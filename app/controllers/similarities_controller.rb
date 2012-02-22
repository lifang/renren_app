# encoding: utf-8
class SimilaritiesController < ApplicationController
  require 'oauth2'
  require 'net/http'

  layout "application"
  @@api_key4 = "d96ca54ba92f4f25bc86a8b6f93b209d"
  @@secret_key4 = "d00a8570b9664c25a50941292d12d5b3"
  @@api_key6= "18037029bfb344349197e7e37c2d72fb"
  @@secret_key6 = "1442cc144c8d4670ab14b2b0332f2d4f"
  def index
    category_id = params[:category].nil? ? 2 : params[:category]
    sql = "select e.id, e.title, e.is_free from examinations e
        where e.category_id = #{category_id} and e.types = #{Examination::TYPES[:OLD_EXAM]}"
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
      redirect_to "/similarities/#{@exam_user.id}?category=#{category_id}"
    else
      flash[:notice]="当前考试未指定试卷。"
      redirect_to "/similarities?category=#{category_id}"
    end
  end

  def show
    eu = ExamUser.find(params[:id])
    @paper_id = eu.paper_id
    @paper = Paper.find(@paper_id)
    @answer_url = "#{Constant::BACK_SERVER_PATH}#{@paper.paper_js_url}".gsub("paperjs/","answerjs/")
    s_url = ExamUser.find(params[:id]).answer_sheet_url
    sheet_url = "#{Constant::PUBLIC_PATH}#{s_url}"
    sheet_url = create_sheet(sheet_outline,params[:id]) unless (s_url && File.exist?(sheet_url))
    @sheet_url = sheet_url
    sheet = get_doc("#{sheet_url}")
    @init_problem = sheet.attributes["init"]
    @sheet = {}
    sheet.each_element do |ele|
      @sheet["#{ele.name}"]="#{ele.text}"
    end
    collection = CollectionInfo.find_by_paper_id_and_user_id(@paper_id,cookies[:user_id])
    @collection = collection.nil? ? [] : collection.question_ids.split(",")
    close_file("#{sheet_url}")
    render :layout=>"similarity"
  end

  #重做卷子
  def redo_paper
    category_id = params[:category].nil? ? 2 : params[:category]
    url=params[:sheet_url]
    doc = get_doc(url)
    collection = ""
    collection = doc.root.elements["collection"].text if doc.root.elements["collection"]
    f=File.new(url,"w+")
    f.write("#{sheet_outline(collection).force_encoding('UTF-8')}")
    f.close
    ExamUser.find(params[:id]).update_attribute("is_submited",false)
    redirect_to "/similarities/#{params[:id]}?category=#{category_id}"
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
    outline += "<collection>"
    outline += "#{collection_str}"
    outline += "</collection>"
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
      this_problem = params["problem"]
      problem_id = this_problem["id"]
      this_question = this_problem["questions"]["#{params["question_index"]}"]
      question_id = this_question["id"]
      Collection.update_collection(cookies[:user_id].to_i, this_problem, problem_id, this_question, question_id,
        params["paper_id"], params["addition"]["answer"], params["addition"]["analysis"], params["user_answer"])
      CollectionInfo.update_collection_infos(params["paper_id"].to_i, cookies[:user_id].to_i, [question_id])
    end
    
    respond_to do |format|
      format.json {
        render :json=>""
      }
    end
  end

  #添加收藏(题面内小题)
  def add_collection
    collection = Collection.find_or_create_by_user_id(cookies[:user_id].to_i)
    path = Collection::COLLECTION_PATH + "/" + Time.now.to_date.to_s
    url = path + "/#{collection.id}.js"
    collection.set_collection_url(path, url)
    already_hash = {}
    last_problems = ""
    file = File.open(Constant::PUBLIC_PATH + collection.collection_url)
    last_problems = file.read
    unless last_problems.nil? or last_problems.strip == ""
      already_hash = JSON(last_problems.gsub("collections = ", ""))
    else
      already_hash = {"problems" => {"problem" => []}}
    end
    is_problem_in = collection.update_question_in_collection(already_hash,
      params[:problem_id].to_i, params[:question_id].to_i,
      params[:question_answer], params[:question_analysis], params[:user_answer])
    if is_problem_in == false
      problem_json = params[:problem_json].class.to_s == "String" ?
        JSON(params[:problem_json]) : params[:problem_json]
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
        render :json => {:message => "收藏成功！"}
      }
    end
  end

  def ajax_report_error
    find_arr = ReportError.find_by_sql("select id from report_errors where user_id=#{params["post"]["user_id"]} and question_id=#{params["post"]["question_id"]} and error_type=#{params["post"]["error_type"]}")
    if find_arr.length>0
      data={:message=>"您已经提交过此错误，感谢您的支持。"}
    else
      reporterror = ReportError.new(params["post"])
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
    words = params["words"].split(";")
    word_index=0
    data={}
    words.each do |word|
      @word = Word.find_by_sql("select * from words where name = '#{word}'")
      if @word.length>0
        @word = @word[0]
        sentences=[]
        @word.word_sentences.each do |sentence|
          sentences << sentence.description
        end
        sentences = sentences.join(";")
        data[word_index]={:id=>@word.id,:name=>@word.name,:category_id=>@word.category_id,:en_mean=>@word.en_mean,:ch_mean=>@word.ch_mean,:types=>Word::TYPES[@word.types],:phonetic=>@word.phonetic,:enunciate_url=>@word.enunciate_url,:sentences=>sentences}
        word_index += 1
      end
    end
    if word_index==0
      data={"error"=>"抱歉，无法查询到相关词汇信息"}
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end

  #单词加入背诵列表
  def ajax_add_word
    word_id = params[:word_id]
    @message=""
    if Word.find(word_id).level && Word.find(word_id).level<=Word::WORD_LEVEL[:SECOND]
      @message="该单词为必备单词，无须添加"
    else
      relation = UserWordRelation.find_by_sql("select id from user_word_relations where user_id=#{cookies[:user_id]} and word_id=#{word_id}")[0]
      if relation
        @message="该单词已经添加。您可以登录赶考网进行背诵"
      else
        relation = UserWordRelation.new(:user_id=>cookies[:user_id],:word_id=>word_id.to_i,:status=>UserWordRelation::STATUS[:NOMAL])
        if relation.save
          @message="单词添加成功。您可以登录赶考网进行背诵"
        else
          @message="单词添加失败"
        end
      end
    end
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


  def cet4
    
  end

  #oauth登录(四级登录)
  def oauth_login_cet4
    user_info = return4_user(params[:access_token])[0]
    cookies[:access_token] = params[:access_token]
    @user=User.where("code_id=#{user_info["uid"].to_s} and code_type='renren'").first
    @user=User.create(:code_id=>user_info["uid"],:code_type=>'renren',:name=>user_info["name"],:username=>user_info["name"]) unless @user
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_FOUR, cookies[:user_id].to_i)
    redirect_to "/similarities?category=#{Category::LEVEL_FOUR}"
  end

  def return4_user(access_token)
    str = "access_token=#{access_token}"
    str << "format=JSON"
    str << "method=xiaonei.users.getInfo"
    str << "v=1.0"
    str << "#{@@secret_key4}"
    sig = Digest::MD5.hexdigest(str)

    query = {
      :access_token => "#{access_token}",
      :format => 'JSON',
      :method => 'xiaonei.users.getInfo',
      :v => '1.0',
      :sig => sig
    }
    return JSON Net::HTTP.post_form(URI.parse(URI.encode("http://api.renren.com/restserver.do")), query).body
  end

  def cet6
    
  end

  def return6_user(access_token)
    str = "access_token=#{access_token}"
    str << "format=JSON"
    str << "method=xiaonei.users.getInfo"
    str << "v=1.0"
    str << "#{@@secret_key6}"
    sig = Digest::MD5.hexdigest(str)

    query = {
      :access_token => "#{access_token}",
      :format => 'JSON',
      :method => 'xiaonei.users.getInfo',
      :v => '1.0',
      :sig => sig
    }
    return JSON Net::HTTP.post_form(URI.parse(URI.encode("http://api.renren.com/restserver.do")), query).body
  end

  #oauth登录(六级登录)
  def oauth_login_cet6
    user_info = return6_user(params[:access_token])[0]
    cookies[:access_token] = params[:access_token]
    @user=User.where("code_id=#{user_info["uid"].to_s} and code_type='renren'").first
    @user=User.create(:code_id=>user_info["uid"],:code_type=>'renren',:name=>user_info["name"],:username=>user_info["name"]) unless @user
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    cookies.delete(:user_role)
    user_order(Category::LEVEL_SIX, cookies[:user_id].to_i)
    redirect_to "/similarities?category=#{Category::LEVEL_SIX}"
  end

  #分享，提供权限(四级)
  def share4
    str = "access_token=#{cookies[:access_token]}"
    str << "comment=众所周知，我正在准备四级。（原来不知道的话，现在也知道了吧。）刚刚在人人发现了一个应用，提供全套的四级真题和录音，灰常和谐，灰常给力。只不过，如果不分享给你们，我就只能用其中的3套而已。所以，你们看到了这条分享。见谅见谅。"
    str << "format=JSON"
    str << "method=share.share"
    str << "type=6"
    str << "url=http://apps.renren.com/english_iv"
    str << "v=1.0"
    str << "#{@@secret_key4}"
    sig = Digest::MD5.hexdigest(str)

    query = {
      :access_token => "#{cookies[:access_token]}",
      :comment=>"众所周知，我正在准备四级。（原来不知道的话，现在也知道了吧。）刚刚在人人发现了一个应用，提供全套的四级真题和录音，灰常和谐，灰常给力。只不过，如果不分享给你们，我就只能用其中的3套而已。所以，你们看到了这条分享。见谅见谅。",
      :format => 'JSON',
      :method => 'share.share',
      :type=>"6",
      :url=>"http://apps.renren.com/english_iv",
      :v => '1.0',
      :sig => sig
    }
    ret =  JSON Net::HTTP.post_form(URI.parse(URI.encode("http://api.renren.com/restserver.do")), query).body

    if ret[:error_code]
      data = {:error=>1,:message=>"分享失败，请重新尝试"}
    else
      order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL])[0]
      if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
        order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
        Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:RENREN],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
          :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:RENREN]])
      end
      data = {:message=>"升级成功"}
    end

    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end

  #分享，提供权限(六级)
  def share6
    str = "access_token=#{cookies[:access_token]}"
    str << "comment=众所周知，我正在准备六级。（原来不知道的话，现在也知道了吧。）刚刚在人人发现了一个应用，提供全套的四级真题和录音，灰常和谐，灰常给力。只不过，如果不分享给你们，我就只能用其中的3套而已。所以，你们看到了这条分享。见谅见谅。"
    str << "format=JSON"
    str << "method=share.share"
    str << "type=6"
    str << "url=http://apps.renren.com/english_vi"
    str << "v=1.0"
    str << "#{@@secret_key6}"
    sig = Digest::MD5.hexdigest(str)

    query = {
      :access_token => "#{cookies[:access_token]}",
      :comment=>"众所周知，我正在准备六级。（原来不知道的话，现在也知道了吧。）刚刚在人人发现了一个应用，提供全套的四级真题和录音，灰常和谐，灰常给力。只不过，如果不分享给你们，我就只能用其中的3套而已。所以，你们看到了这条分享。见谅见谅。",
      :format => 'JSON',
      :method => 'share.share',
      :type=>"6",
      :url=>"http://apps.renren.com/english_vi",
      :v => '1.0',
      :sig => sig
    }
    ret =  JSON Net::HTTP.post_form(URI.parse(URI.encode("http://api.renren.com/restserver.do")), query).body
    if ret[:error_code]
      data = {:error=>1,:message=>"分享失败，请重新尝试"}
    else
      order = Order.where(:user_id=>cookies[:user_id],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL])[0]
      if (order && order.types==Order::TYPES[:TRIAL_SEVEN]) || order.nil?
        order.update_attributes(:status => Order::STATUS[:INVALIDATION]) unless order.nil?
        Order.create(:user_id=>cookies[:user_id],:types=>Order::TYPES[:RENREN],:category_id=>Category::LEVEL_FOUR,:status => Order::STATUS[:NOMAL],:start_time => Time.now.to_datetime, :total_price => 0,
          :end_time => Time.now.to_datetime + Constant::DATE_LONG[:vip].days,:remark=>Order::TYPE_NAME[Order::TYPES[:RENREN]])
      end
      data = {:message=>"升级成功"}
    end
    respond_to do |format|
      format.json {
        render :json=>data
      }
    end
  end


  def refresh
    cookies.delete(:user_role)
    user_role?(cookies[:user_id])
    redirect_to request.referer
  end
  
  
end
