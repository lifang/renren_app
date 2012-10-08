# encoding: utf-8
class SimilaritiesController < ApplicationController
  require 'oauth2'
  require 'net/http'
  require 'base64'
  layout "application"
  
  def index
    @web = params[:web].nil? ? "renren" : params[:web]
    category_id = params[:category].nil? ? 2 : params[:category]
    sql = "select e.id, e.title, e.is_free from examinations e
        where e.category_id = #{category_id} and e.types = #{Examination::TYPES[:OLD_EXAM]} order by created_at "
    @similarities = Examination.paginate_by_sql(sql,
      :per_page => 10, :page => params[:page])
  end



  def show
    @paper = Paper.find(ExaminationPaperRelation.find_by_sql("select paper_id from examination_paper_relations
                    where examination_id=#{params[:id].to_i} order by  rand() limit 1 ")[0].paper_id)
    @paper_js_url = "#{Constant::BACK_SERVER_PATH}#{@paper.paper_js_url}"
    @answer_js_url = "#{Constant::BACK_SERVER_PATH}#{@paper.paper_js_url}".gsub("paperjs/","answerjs/")
    render :layout=>"similarity"
  end

  #重做卷子
  def redo_paper
    web = params[:web].nil? ? "renren" : params[:web]
    redirect_to "/similarities/#{params[:id]}?category=#{params[:category]}&web=#{web}"
  end

  #创建答卷
  def create_sheet(sheet_outline,exam_user_id)
    dir = "#{Constant::PUBLIC_PATH}/sheets"
    Dir.mkdir(dir) unless File.directory?(dir)
    dir = "#{dir}/#{Time.now.strftime("%Y%m%d")}"
    Dir.mkdir(dir) unless File.directory?(dir)
    file_name = "/#{exam_user_id}.xml"
    url = dir + file_name
    unless File.exist?(url)
      ExamUser.find(exam_user_id).update_attribute("answer_sheet_url","/sheets/#{Time.now.strftime("%Y%m%d")}#{file_name}")
      f=File.new(url,"w+")
      f.write("#{sheet_outline.force_encoding('UTF-8')}")
      f.close
    end
    return url
  end

  def sheet_outline(collection_str = "")
    outline = "<?xml version='1.0' encoding='UTF-8'?>"
    outline += "<sheet init='0' status='0'>"
    outline += "</sheet>"
    return outline
  end


  #添加收藏(题面后小题)
  def ajax_add_collect
    if params[:sheet_url]!="" && params[:sheet_url]!=nil
      #解析参数
      this_problem = JSON params["problem"]
      this_question = this_problem["questions"]["question"][params["question_index"].to_i]
      this_addition = JSON params["addition"]
      puts "this_problem = #{this_problem}"
      puts "this_question = #{this_question}"
      puts "params['addition'] = #{this_addition}"
      puts "params['user_answer'] = #{params["user_answer"]}"
      problem_id = this_problem["id"]
      question_id = this_question["id"]
      Collection.update_collection(cookies[:user_id].to_i, this_problem, problem_id, this_question, question_id ,params["paper_id"], this_addition["answer"], this_addition["analysis"], params["user_answer"], params["category_id"])
      CollectionInfo.update_collection_infos(params["paper_id"].to_i, cookies[:user_id].to_i, [question_id])
    end

    respond_to do |format|
      format.json {
        render :json=>{:message => "收藏成功！你可以登录赶考网查看你的收藏"}
      }
    end
  end

  #添加收藏(题面内小题)
  def add_collection
    collection = Collection.find_or_create_by_user_id_and_category_id(cookies[:user_id].to_i, params[:category_id].to_i)
    path = Collection::COLLECTION_PATH + "/" + Time.now.to_date.to_s
    url = path + "/#{collection.id}.js"
    collection.set_collection_url(path, url)
    already_hash = {}
    last_problems = ""
    file = File.open(Constant::PUBLIC_PATH + collection.collection_url)
    last_problems = file.read
    file.close
    unless last_problems.nil? or last_problems.strip == ""
      already_hash = JSON(last_problems.gsub("collections = ", ""))
    else
      already_hash = {"problems" => {"problem" => []}}
    end
    is_problem_in = collection.update_question_in_collection(already_hash,
      params[:problem_id].to_i, params[:question_id].to_i,
      params[:question_answer], params[:question_analysis], params[:user_answer])
    if is_problem_in == false
      problem_json = JSON(params[:problem_json])
      new_col_problem = collection.update_problem_hash(problem_json, params[:paper_id],
        params[:question_answer], params[:question_analysis], params[:user_answer], params[:question_id].to_i)
      already_hash["problems"]["problem"] << new_col_problem
    end
    collection_js = "collections = " + already_hash.to_json.to_s
    path_url = collection.collection_url.split("/")
    collection.generate_collection_url(collection_js, "/" + path_url[1] + "/" + path_url[2], collection.collection_url)

    CollectionInfo.update_collection_infos(params[:paper_id].to_i, cookies[:user_id].to_i, [params[:question_id]])

    respond_to do |format|
      format.json {
        render :json => {:message => "收藏成功！你可以登录赶考网查看你的收藏"}
      }
    end
  end

  def update_collection
    this_problem = JSON params[:problem_json]
    this_question = nil
    unless this_problem["questions"]["question"].nil?
      new_col_questions = this_problem["questions"]["question"]
      if new_col_questions.class.to_s == "Hash"
        this_question = new_col_questions
      else
        new_col_questions.each do |question|
          if question["id"].to_i == params[:question_id].to_i
            this_question = question
            break
          end
        end unless new_col_questions.blank?
      end
    end
    Collection.update_collection(cookies[:user_id].to_i, this_problem,
      params[:problem_id], this_question, params[:question_id],
      params[:paper_id], params[:question_answer], params[:question_analysis], 
      params[:user_answer], params[:category_id].to_i)

    CollectionInfo.update_collection_infos(params[:paper_id].to_i, cookies[:user_id].to_i, [params[:question_id]])
    respond_to do |format|
      format.json {
        render :json => {:message => "收藏成功！你可以登录赶考网查看你的收藏"}
      }
    end
  end

  def ajax_report_error
    find_arr = ReportError.find_by_sql("select id from report_errors where user_id=#{params["post"]["user_id"]} and question_id=#{params["post"]["question_id"]} and error_type=#{params["post"]["error_type"]}")
    if find_arr.length>0
      data={:message=>"您已经提交过此错误，感谢您的支持。"}
    else
      reporterror = params["post"]
      reporterror[:status] = ReportError::STATUS[:UNSOVLED]
      reporterror = ReportError.new(reporterror)
      if reporterror.save
        data={:message=>"错误报告提交成功"}
      else
        data={:message=>"错误报告提交失败"}
      end
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end

  #START 人人网相关

  def  renren_like
    app_id = params["appid"]
    redirect_to "http://widget.renren.com/dialog/friends?target_id=#{Constant::RENREN_ID}&app_id=#{app_id}&redirect_uri=#{Constant::SERVER_PATH}/similarities/close_window"
  end

  def close_window
    render :inline=>"<script>window.close();</script>"
  end


  #人人四级应用相关信息
  @@client_id4 = "180526"
  @@secret_key4 = "d00a8570b9664c25a50941292d12d5b3"

  #cet_four
  #  @@client_id4 = "166937"
  #  @@secret_key4 = "f4fa7ef75e934c2b884a6512a32d625f"

  def cet4
    @client_id = @@client_id4
  end

  def cet4_url_generate
    render :inline=>"<script type='text/javascript'>var p = window.location.href.split('#');var pr = p.length>1 ? p[1] : '';window.location.href = '/similarities/oauth_login_cet4?'+pr;</script>"
  end
  #
  #---------------------------------------------------------------------------------------

  #人人六级应用相关信息
  @@client_id6 = "180533"
  @@api_key6= "18037029bfb344349197e7e37c2d72fb"
  @@secret_key6 = "1442cc144c8d4670ab14b2b0332f2d4f"

  #cet_six
  #  @@client_id6 = "180459"
  #  @@secret_key6 = "68e04945b0d34cfb9e2091463f8f2f24"
  

  def cet6
    @client_id = @@client_id6
  end

  def cet6_url_generate
    render :inline=>"<script type='text/javascript'>var p = window.location.href.split('#');var pr = p.length>1 ? p[1] : '';window.location.href = '/similarities/oauth_login_cet6?'+pr;</script>"
  end

  #oauth登录(六级登录)

  def renren_ky
   @client_id = @@client_id4
  end

  #END  人人网相关


  # START 新浪微博相关

  #四级
  def sina_cet4
    #上线
    @app_key = "2422557611"
    @app_secret = "141eb2a5ded8ff672fb05e87769d3ecb"

    #    本地测试
    #    @app_key = "4140866006"
    #    @app_secret = "2367900785a62214eeb4afa02b3cd672"

    @web = "sina"
    #    @login = false
    #    signed_request = params[:signed_request]
    #    if signed_request
    #      list = signed_request.split(".")
    #      encoded_sig,pay_load =list[0],list[1]
    #      base_str = Base64.decode64(pay_load)
    #      base_str = base_str.split(",\"referer\"")[0]
    #      base_str = base_str[-1]=="}" ? base_str : "#{base_str}}"
    #      @data = JSON (base_str)
    #      if @data["user_id"] && @data["oauth_token"]
    #        @login = true
    #        cookies[:access_token] = @data["oauth_token"]
    #        response = sina_get_user(cookies[:access_token],@data["user_id"])
    #        @user=User.find_by_code_id_and_code_type("#{@data["user_id"]}","sina")
    #        if @user
    #          ActionLog.login_log(@user.id)
    #        else
    #          @user=User.create(:code_id=>@data["user_id"],:code_type=>'sina',:name=>response["screen_name"],
    #            :username=>response["screen_name"], :from => User::U_FROM[:APP])
    #          #发送推广微博(审核时隐藏)
    #          comment = "我正在使用应用--大学英语四级真题  http://apps.weibo.com/english_iv"
    #          sina_send_message(cookies[:access_token],comment)
    #        end
    #        cookies[:user_id] = @user.id
    #        cookies[:user_name] = @user.name
    #        cookies.delete(:user_role)
    #        user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
    #      end
    #    end
  end
  #
  #---------------------------------------------------------------------------------------
  #六级
  def sina_cet6
    @app_key = "2416971947"
    @app_secret = "2a9ec8a4c028721eda0e3a0d751d724a"
    @web = "sina"
    @login = false
    signed_request = params[:signed_request]
    if signed_request
      list = signed_request.split(".")
      encoded_sig,pay_load =list[0],list[1]
      base_str = Base64.decode64(pay_load)
      base_str = base_str.split(",\"referer\"")[0]
      base_str = base_str[-1]=="}" ? base_str : "#{base_str}}"
      @data = JSON (base_str)
      if @data["user_id"] && @data["oauth_token"]
        @login = true
        cookies[:access_token] = @data["oauth_token"]
        response = sina_get_user(cookies[:access_token],@data["user_id"])
        @user=User.find_by_code_id_and_code_type("#{@data["user_id"]}","sina")
        if @user
          ActionLog.login_log(@user.id)
        else
          @user=User.create(:code_id=>@data["user_id"],:code_type=>'sina',:name=>response["screen_name"],
            :username=>response["screen_name"], :from => User::U_FROM[:APP])
          comment = "我正在使用应用--大学英语六级真题 http://apps.weibo.com/english_vi"
          sina_send_message(cookies[:access_token],comment)
        end
        cookies[:user_id] = @user.id
        cookies[:user_name] = @user.name
        cookies.delete(:user_role)
        user_order(Category::LEVEL_SIX, cookies[:user_id].to_i)
      end
    end
  end

  #微博分享，提供权限(六级)
  def sina_share6
    if Constant::SINA_ORDERS_SUM[:cet_6] && get_share_sum(Order::TYPES[:SINA],Category::LEVEL_SIX)>=Constant::SINA_ORDERS_SUM[:cet_6]
      data = {:error=>"人数已满",:message=>"<p>当天#{Constant::SINA_ORDERS_SUM[:cet_6]}个免费账号已经被抢完T_T，明天再来抢吧。</p>"}
    else
      comment="#{params["message"]}"
      ret = sina_send_message(cookies[:access_token],comment)
      if ret["error_code"]
        puts ret
        data = {:error=>1,:message=>"微博发送失败，请重新尝试"}
      else
        order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_SIX,:status => Order::STATUS[:NOMAL])[0]
        if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
          order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
          Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:SINA],:category_id=>Category::LEVEL_SIX,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
            :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:SINA]])
          data = {:message=>"升级正式用户成功"}
        else
          data = {:message=>"您已经是正式用户，请等待页面刷新"}
        end
      end
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end

  def sina_ky
    @web="sina"
  end
  # END 新浪微博相关


  
  #
  #------------------------------------------------------------------------
  #



  #  #START  腾讯相关
  #

  #检测是否已进入过应用
  def check_status
    user=User.first(:conditions=>"code_id='#{params[:openid]}' and code_type='qq'")
    if user.nil?
      cookies[:openid]=params[:openid]
      data=true
    else
      cookies.delete(:user_role)
      cookies[:user_id]=user.id
      user_role?(cookies[:user_id])
      data=false
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end

  #qq登录
  def request_qq
    redirect_to "#{SimilaritiesHelper::REQUEST_URL_QQ}?#{SimilaritiesHelper::REQUEST_ACCESS_TOKEN.map{|k,v|"#{k}=#{v}"}.join("&")}"
  end
  
  def manage_qq
    listen=false
    begin
      meters=params[:access_token].split("&")
      access_token=meters[0].split("=")[1]
      expires_in=meters[1].split("=")[1].to_i
      openid=params[:open_id]
      @user= User.find_by_open_id(openid)
      if @user.nil?
        user_url="https://graph.qq.com"
        user_route="/user/get_user_info?access_token=#{access_token}&oauth_consumer_key=#{Constant::APPID}&openid=#{openid}"
        user_info=create_get_http(user_url,user_route)
        user_info["nickname"]="qq用户" if user_info["nickname"].nil?||user_info["nickname"]==""
        @user=User.create(:code_type=>'qq',:code_id=>cookies[:openid],:name=>user_info["nickname"],:username=>user_info["nickname"],:open_id=>openid ,:access_token=>access_token,:end_time=>Time.now+expires_in.seconds,:from=>User::U_FROM[:APP])
        listen=true
      else
        ActionLog.login_log(@user.id)
        @user.update_attributes(:code_id=>cookies[:openid]) if @user.code_id.nil? or @user.code_id!=cookies[:openid]
        if @user.access_token.nil? || @user.access_token=="" || @user.access_token!=access_token
          @user.update_attributes(:access_token=>access_token,:end_time=>Time.now+expires_in.seconds)
        end
      end
      cookies.delete(:openid)
      cookies[:user_id] ={:value =>@user.id, :path => "/", :secure  => false}
      cookies[:user_name] ={:value =>@user.username, :path => "/", :secure  => false}
      user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
      data=true
    rescue
      data=false
    end
    respond_to do |format|
      format.json {
        render :json=>{:yes=>data,:category=>Category::LEVEL_FOUR,:listen=>listen}
      }
    end
  end

  def qq_confirm
    refresh=false
    if Constant::FREE_QQ_COUNT[:cet_4] && get_share_sum(Order::TYPES[:QQ],Category::LEVEL_FOUR)>=Constant::FREE_QQ_COUNT[:cet_4]
      message="<p>今天#{Constant::FREE_QQ_COUNT[:cet_4]}个免费名额被抢完T_T，明天再来抢吧</p>"
    else
      order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL])[0]
      if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
        Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:QQ],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
          :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:QQ]])
        order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
        cookies.delete(:user_role)
        user_role?(cookies[:user_id])
        refresh=true
        message="升级正式用户成功"
      else
        message="您已经是正式用户，请等待页面刷新"
      end
    end
    respond_to do |format|
      format.json {
        render :json=>{:notice=>message,:fresh=>refresh,:category=>Category::LEVEL_FOUR}
      }
    end
  end


  def request_qq6
    redirect_to "#{SimilaritiesHelper::REQUEST_URL_QQ}?#{SimilaritiesHelper::REQUEST_ACCESS_TOKEN_6.map{|k,v|"#{k}=#{v}"}.join("&")}"
  end

  def manage_qq_6
    listen=false
    begin
      meters=params[:access_token].split("&")
      access_token=meters[0].split("=")[1]
      expires_in=meters[1].split("=")[1].to_i
      openid=params[:open_id]
      @user= User.find_by_open_id(openid)
      if @user.nil?
        user_url="https://graph.qq.com"
        user_route="/user/get_user_info?access_token=#{access_token}&oauth_consumer_key=#{Constant::APPID}&openid=#{openid}"
        user_info=create_get_http(user_url,user_route)
        user_info["nickname"]="qq用户" if user_info["nickname"].nil?||user_info["nickname"]==""
        listen=true
        @user=User.create(:code_type=>'qq',:code_id=>cookies[:openid],:name=>user_info["nickname"],:username=>user_info["nickname"],:open_id=>openid ,:access_token=>access_token,:end_time=>Time.now+expires_in.seconds,:from=>User::U_FROM[:APP])
      else
        ActionLog.login_log(@user.id)
        @user.update_attributes(:code_id=>cookies[:openid]) if @user.code_id.nil? or @user.code_id!=cookies[:openid]
        if @user.access_token.nil? || @user.access_token=="" || @user.access_token!=access_token
          @user.update_attributes(:access_token=>access_token,:end_time=>Time.now+expires_in.seconds)
        end
      end
      cookies.delete(:openid)
      cookies[:user_id] ={:value =>@user.id, :path => "/", :secure  => false}
      cookies[:user_name] ={:value =>@user.username, :path => "/", :secure  => false}
      user_order(Category::LEVEL_SIX, cookies[:user_id].to_i)
      data=true
    rescue
      data=false
    end
    respond_to do |format|
      format.json {
        render :json=>{:yes=>data,:category=>Category::LEVEL_SIX,:listen=>listen}
      }
    end
  end

  def qq_cet4
    @web="qq"
  end


  def qq_cet6
    @web="qq"
  end

  def qq_ky
    @web="qq"
  end
  #END  腾讯相关


  
  #
  #------------------------------------------------------------------------
  #



  #START 百度相关

  @@baidu_api_key4 = "qGR1RoeMxVHMHRhPRcKSOLn2"
  @@baidu_secret_key4 = "k4Iogw9wgXzRiX2p6uFd5167bmE0zzwG"
  @@baidu_redirect_uri4 = "#{Constant::SERVER_PATH}/similarities/baidu_login4"

  def baidu_cet4
    @web = "baidu"
    @api_key = @@baidu_api_key4
    @redirect_uri = @@baidu_redirect_uri4
    if params[:bd_user] && params[:bd_user]!="0"
      @user=User.find_by_code_id_and_code_type(params[:bd_user],"baidu")
      if @user
        ActionLog.login_log(@user.id)
        cookies[:user_id]=@user.id
        cookies[:user_name]=@user.username
        cookies.delete(:user_role)
        user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
        redirect_to "/similarities?category=#{Category::LEVEL_FOUR}&web=baidu"
        return false
      end
    end
  end

  def baidu_login4
    code = params["code"]
    ret_access_token = baidu_access_token(code,@@baidu_api_key4,@@baidu_secret_key4,@@baidu_redirect_uri4)
    cookies[:access_token] = ret_access_token["access_token"]
    ret_user = baidu_get_user(cookies[:access_token])
    @user=User.find_by_code_id_and_code_type("#{ret_user["uid"]}","baidu")
    if @user
      ActionLog.login_log(@user.id)
    else
      cookies[:first]={:value => "first", :path => "/", :secure  => false}
      @user=User.create(:code_id=>ret_user["uid"],:code_type=>'baidu',:name=>ret_user["uname"],
        :username=>ret_user["uname"], :from => User::U_FROM[:APP])
    end
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
    render :inline=>"<script type='text/javascript'>window.parent.location.href='/similarities?category=#{Category::LEVEL_FOUR}&web=baidu'</script>"
  end

  def baidu_share4
    if Constant::BAIDU_ORDERS_SUM[:cet_4] && get_share_sum(Order::TYPES[:BAIDU],Category::LEVEL_FOUR)>=Constant::BAIDU_ORDERS_SUM[:cet_4]
      data = {:error=>"人数已满",:message=>"<p>当天#{Constant::BAIDU_ORDERS_SUM[:cet_4]}个免费账号已经被抢完T_T，明天再来抢吧。</p>"}
    else
      order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL])[0]
      if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
        order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
        Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:BAIDU],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
          :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:BAIDU]])
        data = {:message=>"升级正式用户成功"}
      else
        data = {:message=>"您已经是正式用户，请等待页面刷新"}
      end
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end

  def baidu_search4
    @web = "baidu"
  end


  @@baidu_api_key6 = "28Df4AX3I59YSwCaqlpgHmmG"
  @@baidu_secret_key6 = "spkM4urRXmPhQNEpkzS90DX4yLyINDV0"
  @@baidu_redirect_uri6 = "#{Constant::SERVER_PATH}/similarities/baidu_login6"

  def baidu_cet6
    @web = "baidu"
    @api_key = @@baidu_api_key6
    @redirect_uri = @@baidu_redirect_uri6
    if params[:bd_user] && params[:bd_user]!="0"
      @user=User.find_by_code_id_and_code_type(params[:bd_user],"baidu")
      if @user
        ActionLog.login_log(@user.id)
        cookies[:user_id]=@user.id
        cookies[:user_name]=@user.username
        cookies.delete(:user_role)
        user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
        redirect_to "/similarities?category=#{Category::LEVEL_SIX}&web=baidu"
        return false
      end
    end
  end

  def baidu_login6
    code = params["code"]
    ret_access_token = baidu_access_token(code,@@baidu_api_key6,@@baidu_secret_key6,@@baidu_redirect_uri6)
    cookies[:access_token] = ret_access_token["access_token"]
    ret_user = baidu_get_user(cookies[:access_token])
    @user=User.find_by_code_id_and_code_type("#{ret_user["uid"]}","baidu")
    if @user
      ActionLog.login_log(@user.id)
    else
      cookies[:first]={:value => "first", :path => "/", :secure  => false}
      @user=User.create(:code_id=>ret_user["uid"],:code_type=>'baidu',:name=>ret_user["uname"],
        :username=>ret_user["uname"], :from => User::U_FROM[:APP])
    end
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_SIX, cookies[:user_id].to_i)
    render :inline=>"<script type='text/javascript'>window.parent.location.href='/similarities?category=#{Category::LEVEL_SIX}&web=baidu'</script>"
  end

  def baidu_share6
    if Constant::BAIDU_ORDERS_SUM[:cet_6] && get_share_sum(Order::TYPES[:BAIDU],Category::LEVEL_SIX)>=Constant::BAIDU_ORDERS_SUM[:cet_6]
      data = {:error=>"人数已满",:message=>"<p>当天#{Constant::BAIDU_ORDERS_SUM[:cet_6]}个免费账号已经被抢完T_T，明天再来抢吧。</p>"}
    else
      order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_SIX,:status => Order::STATUS[:NOMAL])[0]
      if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
        order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
        Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:BAIDU],:category_id=>Category::LEVEL_SIX,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
          :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:BAIDU]])
        data = {:message=>"升级正式用户成功"}
      else
        data = {:message=>"您已经是正式用户，请等待页面刷新"}
      end
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end
  
  def baidu_search6
    @web = "baidu"
  end

  def baidu_ky
    @web = "baidu"
  end

  def search_ky
    @web = "baidu"
  end
  
  #END 百度相关
  
end
