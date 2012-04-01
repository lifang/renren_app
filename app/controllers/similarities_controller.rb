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
        where e.category_id = #{category_id} and e.types = #{Examination::TYPES[:OLD_EXAM]}"
    @user = User.find(cookies[:user_id])
    @code_id = @user.code_id.nil? ? "gankao" : @user.code_id
    @similarities = Examination.paginate_by_sql(sql,
      :per_page => 10, :page => params[:page])
    examination_ids = []
    @objects = {}
    @similarities.each { |sim| examination_ids << sim.id }
    exam_users = ExamUser.find_by_sql(["select eu.id, eu.examination_id, eu.is_submited, eu.answer_sheet_url from exam_users eu where eu.user_id = ?
      and eu.examination_id in (?)", cookies[:user_id].to_i, examination_ids])
    exam_users.each { |eu| @objects[eu.examination_id] = [eu.id,eu.is_submited,eu.answer_sheet_url] }
  end

  def join
    category_id = params[:category].nil? ? 2 : params[:category]
    web = params[:web].nil? ? "renren" : params[:web]
    similarity = Examination.find(params[:id])
    #设置考试试卷
    papers_arr=[]
    similarity.papers.each do |paper|
      papers_arr << paper
    end
    if papers_arr.length>0
      @paper = papers_arr.sample
      @exam_user = ExamUser.find_by_sql("select * from exam_users where user_id = #{cookies[:user_id]} and examination_id = #{params[:id]} and paper_id = #{@paper.id}")[0]
      if @exam_user.nil?
        @exam_user = ExamUser.create(:user_id=>cookies[:user_id],:examination_id=>params[:id],:paper_id=>@paper.id)
      end
      redirect_to "/similarities/#{@exam_user.id}?category=#{category_id}&web=#{web}"
    else
      flash[:notice]="当前考试未指定试卷。"
      redirect_to "/similarities?category=#{category_id}&web=#{web}"
    end
  end

  def show
    eu = ExamUser.find(params[:id])
    @paper_id = eu.paper_id
    @paper = Paper.find(@paper_id)
    @user = User.find(eu.user_id)
    @code_id = @user.code_id.nil? ? "gankao" : @user.code_id
    @paper_js_url = "#{Constant::BACK_SERVER_PATH}#{@paper.paper_js_url}"
    @answer_js_url = "#{Constant::BACK_SERVER_PATH}#{@paper.paper_js_url}".gsub("paperjs/","answerjs/")
    s_url = ExamUser.find(params[:id]).answer_sheet_url
    sheet_url = "#{Constant::PUBLIC_PATH}#{s_url}"
    sheet_url = create_sheet(sheet_outline,params[:id]) unless (s_url && File.exist?(sheet_url))
    @sheet_url = sheet_url
    collection = CollectionInfo.find_by_paper_id_and_user_id(@paper_id,cookies[:user_id])
    @collection = collection.nil? ? [] : collection.question_ids.split(",")
    render :layout=>"similarity"
  end

  #重做卷子
  def redo_paper
    web = params[:web].nil? ? "renren" : params[:web]
    exam_user = ExamUser.find(params[:id])
    url="#{Constant::PUBLIC_PATH}#{exam_user.answer_sheet_url}"
    if File.exist?(url)
      doc = get_doc(url)
      collection = ""
      collection = doc.root.elements["collection"].text if doc.root.elements["collection"]
      f=File.new(url,"w+")
      f.write("#{sheet_outline.force_encoding('UTF-8')}")
      f.close
    end
    exam_user.update_attribute("is_submited",false)
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

  #考生保存答案
  def ajax_save_question_answer
    if params[:sheet_url]!="" && params[:sheet_url]!=nil
      url=params[:sheet_url]
      doc = get_doc(url)
      ele_str = "_#{params[:problem_index]}_#{params[:question_index]}"
      doc.attributes["init"].nil? ? doc.add_attribute("init", "#{params[:problem_index]}") : (doc.attributes["init"] = "#{params[:problem_index]}")
      question = doc.elements[ele_str].nil? ? doc.add_element(ele_str) : doc.elements[ele_str]
      question.text.nil? ? question.add_text(params[:answer]) : question.text=params[:answer]
      manage_element(question,{},{"question_type"=>params[:question_type], "correct_type"=>params[:correct_type]})
      write_xml(doc, url)
      #更新action_logs , total_num+1
      log = ActionLog.find_by_sql("select * from action_logs where user_id=#{cookies[:user_id]} and types=#{ActionLog::TYPES[:PRACTICE]} and category_id=#{params[:category_id]} and TO_DAYS(NOW())=TO_DAYS(created_at)")[0]
      log = ActionLog.create(:user_id=>cookies[:user_id],:types=>ActionLog::TYPES[:PRACTICE],:category_id=>params[:category_id],:total_num=>0) unless log
      log.update_attribute("total_num",log.total_num+1)
    end
    respond_to do |format|
      format.json {
        render :json=>""
      }
    end
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

  #ajax载入相关词汇
  def ajax_load_about_words
    words=params[:words].split(";")
    load_words=Word.question_words(words)
    load_words.each do |word|
      arr = []
      word[1].each do |sentence|
        arr << sentence.description
      end
      word[1] = arr.join("|+|")
    end
    respond_to do |format|
      format.json {
        data={:words=>load_words}
        render :json=>data
      }
    end
  end
  
  #单词加入背诵列表
  def ajax_add_word
    word = Word.find(params[:word_id].to_i)
    UserWordRelation.add_nomal_ids(cookies[:user_id], word.id, word.category_id) if word
    @message="单词已添加到你的单词本，你可以登录赶考网进行背诵。"
    respond_to do |format|
      format.json {
        render :json=>{:message=>@message}
      }
    end
  end

  #改变答卷状态（即做完了最后一题）
  def ajax_change_status
    if params[:sheet_url]!="" && params[:sheet_url]!=nil
      ExamUser.find(params[:id]).update_attribute("is_submited",true)
      url=params[:sheet_url]
      doc = get_doc(url)
      doc.attributes["status"] = "1"
      doc.attributes["init"] = "0"
      write_xml(doc, url)
    end
    respond_to do |format|
      format.json {
        render :json=>""
      }
    end
  end

  #获取当天通过分享获取会员的数量
  def get_share_sum(types,category)
    sum = Order.count_by_sql("select count(id) from orders where TO_DAYS(NOW())-TO_DAYS(created_at)=0 and types=#{types} and category_id=#{category} ")
    return sum
  end

  #更新用户权限
  def refresh
    web = params[:web].nil? ? "renren" : params[:web]
    category = params[:category].nil? ? "2" : params[:category]
    success = params[:success]=="success" ? "1" : "0"
    cookies.delete(:user_role)
    user_role?(cookies[:user_id])
    redirect_to "/similarities?category=#{category}&web=#{web}&success=#{success}"
  end

  #载入用户答案
  def ajax_load_sheets
    if File.exist?(params[:sheet_url])
      doc = get_doc(params[:sheet_url])
      data = Hash.from_xml(doc.to_s).to_json
    else
      data = {:message=>"用户答卷载入失败，自动忽略答卷记录",:sheet=>{:status=>0,:init=>0}}
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end

  #获取当前免费名额的数量
  def ajax_free_sum
    order_type = params[:order_type]
    category = params[:category]
    total_sum = category=="2" ? Constant::RENREN_ORDERS_SUM[:cet_4] : Constant::RENREN_ORDERS_SUM[:cet_6] if order_type.to_i == Order::TYPES[:RENREN]
    total_sum = category=="2" ? Constant::SINA_ORDERS_SUM[:cet_4] : Constant::SINA_ORDERS_SUM[:cet_6] if order_type.to_i == Order::TYPES[:SINA]
    total_sum = category=="2" ? Constant::BAIDU_ORDERS_SUM[:cet_4] : Constant::BAIDU_ORDERS_SUM[:cet_6] if order_type.to_i == Order::TYPES[:BAIDU]
    already_sum = get_share_sum(order_type.to_i,category.to_i)
    data={:message=>"今日剩余#{total_sum-already_sum}"}
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

  #oauth登录(四级登录)
  def oauth_login_cet4
    cookies.delete(:first)
    access_token = params["access_token"]
    user_info = renren_get_user(access_token,@@secret_key4)
    if user_info[0]
      user_info = user_info[0]
    else
      render :inline=>"#{user_info}"
      return false
    end
    cookies[:access_token] = access_token
    @user=User.find_by_code_id_and_code_type("#{user_info["uid"]}","renren")
    if @user
      ActionLog.login_log(@user.id)
    else
      cookies[:first]={:value => "first", :path => "/", :secure  => false}
      @user=User.create(:code_id=>user_info["uid"],:code_type=>'renren',:name=>user_info["name"],:username=>user_info["name"])
    end
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
    redirect_to "/similarities?category=#{Category::LEVEL_FOUR}&web=renren&appid=#{@@client_id4}"
  end

  #人人分享，提供权限(四级)
  def renren_share4
    if Constant::RENREN_ORDERS_SUM[:cet_4] && get_share_sum(Order::TYPES[:RENREN],Category::LEVEL_FOUR)>=Constant::RENREN_ORDERS_SUM[:cet_4]
      data = {:error=>"人数已满",:message=>"<p>今天#{Constant::RENREN_ORDERS_SUM[:cet_4]}个免费名额被抢完T_T，明天再来抢吧</p>"}
    else
      comment="众所周知，我正在准备四级。（原来不知道的话，现在也知道了吧。）刚刚在人人发现了一个应用，提供全套的四级真题和录音，灰常和谐，灰常给力。只不过，如果不分享给你们，我就只能用其中的3套而已。所以，你们看到了这条分享。见谅见谅。"
      ret = renren_send_message(cookies[:access_token],comment,@@secret_key4)
      if ret[:error_code]
        data = {:error=>1,:message=>"分享失败，请重新尝试"}
      else
        order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL])[0]
        if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
          order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
          Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:RENREN],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
            :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:RENREN]])
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
  def oauth_login_cet6
    cookies.delete(:first)
    @client_id = @@client_id6
    access_token = params["access_token"]
    user_info = renren_get_user(access_token,@@secret_key6)
    if user_info[0]
      user_info = user_info[0]
    else
      render :inline=>"#{user_info}"
      return false
    end
    cookies[:access_token] = access_token
    @user=User.find_by_code_id_and_code_type(user_info["uid"],'renren')
    if @user
      ActionLog.login_log(@user.id)
    else
      cookies[:first]={:value => "first", :path => "/", :secure  => false}
      @user=User.create(:code_id=>user_info["uid"],:code_type=>'renren',:name=>user_info["name"],:username=>user_info["name"])
    end
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_SIX, cookies[:user_id].to_i)
    redirect_to "/similarities?category=#{Category::LEVEL_SIX}&web=renren&appid=#{@@client_id6}"
  end

  #人人分享，提供权限(六级)
  def renren_share6
    if Constant::RENREN_ORDERS_SUM[:cet_6] && get_share_sum(Order::TYPES[:RENREN],Category::LEVEL_SIX)>=Constant::RENREN_ORDERS_SUM[:cet_6]
      data = {:error=>"人数已满",:message=>"<p>当天#{Constant::RENREN_ORDERS_SUM[:cet_6]}个免费账号已经被抢完T_T，明天再来抢吧。</p>"}
    else
      comment="众所周知，我正在准备六级。（原来不知道的话，现在也知道了吧。）刚刚在人人发现了一个应用，提供全套的六级真题和录音，灰常和谐，灰常给力。只不过，如果不分享给你们，我就只能用其中的3套而已。所以，你们看到了这条分享。见谅见谅。"
      ret = renren_send_message(cookies[:access_token],comment,@@secret_key6)
      if ret[:error_code]
        data = {:error=>1,:message=>"分享失败，请重新尝试"}
      else
        order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_SIX,:status => Order::STATUS[:NOMAL])[0]
        if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
          order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
          Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:RENREN],:category_id=>Category::LEVEL_SIX,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
            :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:RENREN]])
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


  #END  人人网相关



  # START 开心网相关

  #四级
  def kaixin_cet4
    @app_id = "100028114"
    @api_key = "937024390647ac79dc37fa68fc8a29fc"
    @secret_key = "3c41f0ff19ebb1c939ba6984f98f1c95"
    @web = "kaixin"
    signed_request = params[:signed_request]
    if signed_request
      list = signed_request.split(".")
      encoded_sig,pay_load =list[0],list[1]
      base_str = Base64.decode64(pay_load)
      base_str = base_str[-1]=="}" ? base_str : "#{base_str}}"
      @data = JSON (base_str)
      @login = false
      if @data["user_id"] && @data["oauth_token"]
        @login = true
        cookies[:access_token] = @data["oauth_token"]
        response = kaixin_get_user(cookies[:access_token])
        @user=User.find_by_code_id_and_code_type("#{@data["user_id"]}","kaixin")
        if @user
          ActionLog.login_log(@user.id)
        else
          @user=User.create(:code_id=>@data["user_id"],:code_type=>'kaixin',:name=>response["name"],:username=>response["name"])
        end
        cookies[:user_id] = @user.id
        cookies[:user_name] = @user.name
        cookies.delete(:user_role)
        user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
      end
    end
  end

  #
  #---------------------------------------------------------------------------------------
  #六级
  
  def kaixin_cet6
    @app_id = "100028098"
    @api_key = "533679299063ffcf7f8e683c98cdf443"
    @secret_key = "6d8bd604523ad6a3b4d89b82d15e9245"
    @web = "kaixin"
    signed_request = params[:signed_request]
    if signed_request
      list = signed_request.split(".")
      encoded_sig,pay_load =list[0],list[1]
      base_str = Base64.decode64(pay_load)
      base_str = base_str[-1]=="}" ? base_str : "#{base_str}}"
      @data = JSON (base_str)
      @login = false
      if @data["user_id"] && @data["oauth_token"]
        @login = true
        cookies[:access_token] = @data["oauth_token"]
        response = kaixin_get_user(cookies[:access_token])
        @user=User.find_by_code_id_and_code_type("#{@data["user_id"]}","kaixin")
        if @user
          ActionLog.login_log(@user.id)
        else
          @user=User.create(:code_id=>@data["user_id"],:code_type=>'kaixin',:name=>response["name"],:username=>response["name"])
        end
        cookies[:user_id] = @user.id
        cookies[:user_name] = @user.name
        cookies.delete(:user_role)
        user_order(Category::LEVEL_SIX, cookies[:user_id].to_i)
      end
    end
  end
  # END 开心网相关


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
          @user=User.create(:code_id=>@data["user_id"],:code_type=>'sina',:name=>response["screen_name"],:username=>response["screen_name"])
          #发送推广微博(审核时隐藏)
          comment = "我正在使用应用--大学英语四级真题  http://apps.weibo.com/english_iv"
          sina_send_message(cookies[:access_token],comment)
        end
        cookies[:user_id] = @user.id
        cookies[:user_name] = @user.name
        cookies.delete(:user_role)
        user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
      end
    end
  end

  #微博分享，提供权限(四级)
  def sina_share4
    if Constant::SINA_ORDERS_SUM[:cet_4] && get_share_sum(Order::TYPES[:SINA],Category::LEVEL_FOUR)>=Constant::SINA_ORDERS_SUM[:cet_4]
      data = {:error=>"人数已满",:message=>"<p>今天#{Constant::SINA_ORDERS_SUM[:cet_4]}个免费名额被抢完T_T，明天再来抢吧</p>"}
    else
      comment="#{params["message"]}"
      ret = sina_send_message(cookies[:access_token],comment)
      if ret["error_code"]
        puts ret
        data = {:error=>1,:message=>"微博发送失败，请重新尝试"}
      else
        order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL])[0]
        if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
          order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
          Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:SINA],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
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
          @user=User.create(:code_id=>@data["user_id"],:code_type=>'sina',:name=>response["screen_name"],:username=>response["screen_name"])
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
  # END 新浪微博相关


  
  #
  #------------------------------------------------------------------------
  #



  #START  腾讯相关


  #END  腾讯相关


  
  #
  #------------------------------------------------------------------------
  #



  #START 百度相关

  @@baidu_api_key4 = "qGR1RoeMxVHMHRhPRcKSOLn2"
  @@baidu_secret_key4 = "k4Iogw9wgXzRiX2p6uFd5167bmE0zzwG"
  @@baidu_redirect_uri4 = "#{Constant::SERVER_PATH}/similarities/baidu_login4"

  def baidu_cet4
    @api_key = @@baidu_api_key4
    @redirect_uri = @@baidu_redirect_uri4
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
      @user=User.create(:code_id=>ret_user["uid"],:code_type=>'baidu',:name=>ret_user["uname"],:username=>ret_user["uname"])
    end
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
    redirect_to "/similarities?category=#{Category::LEVEL_FOUR}&web=baidu"
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
    render :inline=>"<script src='http://app.baidu.com/static/appstore/monitor.st'></script><img src='/assets/search4.png' onclick=\"javascript:window.parent.location.href='http://apps.baidu.com/english_iv'\"></img>"
  end


  @@baidu_api_key6 = "28Df4AX3I59YSwCaqlpgHmmG"
  @@baidu_secret_key6 = "spkM4urRXmPhQNEpkzS90DX4yLyINDV0"
  @@baidu_redirect_uri6 = "#{Constant::SERVER_PATH}/similarities/baidu_login6"

  def baidu_cet6
    @api_key = @@baidu_api_key6
    @redirect_uri = @@baidu_redirect_uri6
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
      @user=User.create(:code_id=>ret_user["uid"],:code_type=>'baidu',:name=>ret_user["uname"],:username=>ret_user["uname"])
    end
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_SIX, cookies[:user_id].to_i)
    redirect_to "/similarities?category=#{Category::LEVEL_SIX}&web=baidu"
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
    render :inline=>"<script src='http://app.baidu.com/static/appstore/monitor.st'></script><img src='/assets/search6.png' onclick=\"javascript:window.parent.location.href='http://apps.baidu.com/english_vi'\"></img>"
  end

  #END 百度相关

  
end
