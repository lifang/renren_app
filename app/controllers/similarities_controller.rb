# encoding: utf-8
class SimilaritiesController < ApplicationController
  require 'oauth2'
  require 'net/http'

  layout "application"

  @@secret_key = "f4fa7ef75e934c2b884a6512a32d625f"

  def index
    category_id = params[:category].nil? ? 2 : params[:category]
    sql = "select e.id, e.title, e.is_free from examinations e
        where e.category_id = #{category_id} and e.types = #{Examination::TYPES[:OLD_EXAM]}"
    #    if !params[:category_type].nil? and params[:category_type] == Examination::IS_FREE[:YES].to_s
    #      sql += " and e.is_free = #{Examination::IS_FREE[:YES]}"
    #    elsif !params[:category_type].nil? and params[:category_type] == Examination::IS_FREE[:NO].to_s
    #      sql += " and (e.is_free = #{Examination::IS_FREE[:NO]} or e.is_free is null)"
    #    end
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
    p = Paper.find(@paper_id)
    paper = File.open("#{Constant::BACK_PUBLIC_PATH}#{p.paper_js_url}")
    @answer_js_url = "#{Constant::BACK_SERVER_PATH}#{p.paper_js_url}".gsub("paperjs/","answerjs/")
    @paper = (JSON paper.read()[8..-1])["paper"]
    #组织 @paper
    #    @title = @paper["base_info"]["title"]
    @paper["blocks"]["block"] = @paper["blocks"]["block"].nil? ? [] : (@paper["blocks"]["block"].class==Array) ? @paper["blocks"]["block"] : [@paper["blocks"]["block"]]
    @paper["blocks"]["block"].each do |block|
      if block["problems"]
        block["problems"]["problem"] = (block["problems"]["problem"].nil?) ? [] : ((block["problems"]["problem"].class==Array) ? block["problems"]["problem"] : [block["problems"]["problem"]])
        block["problems"]["problem"].each do |problem|
          problem["questions"]["question"] = problem["questions"]["question"].nil? ? [] : (problem["questions"]["question"].class==Array) ? problem["questions"]["question"] : [problem["questions"]["question"]] if problem["questions"]
        end
      end
    end
    #生成考生答卷
    s_url = ExamUser.find(params[:id]).answer_sheet_url
    @sheet_url = "#{Constant::PUBLIC_PATH}#{s_url}"
    @sheet_url = create_sheet(sheet_outline,params[:id]) unless (s_url && File.exist?(@sheet_url))
    @sheet = get_doc("#{@sheet_url}")
    close_file("#{@sheet_url}")
    render :layout=>"similarity"
  end

  #重做卷子
  def redo
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
    dir = "#{Rails.root}/public/sheets"
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
      this_problem = JSON params["problem"]
      problem_id = this_problem["id"]
      this_question = this_problem["questions"]["question"][params["question_index"].to_i]
      question_id = this_question["id"]
      Collection.update_collection(cookies[:user_id].to_i, this_problem, problem_id, this_question, question_id,
        params["paper_id"], params["addition"]["answer"], params["addition"]["analysis"], params["user_answer"])
      #在sheet中记录小题的收藏状态
      doc = get_doc(params[:sheet_url])
      new_str = "_#{params["problem_index"]}_#{params["question_index"]}"
      collection =doc.root.elements["collection"]
      collection.text.nil? ? collection.add_text(new_str) : collection.text="#{collection.text},#{new_str}"
      write_xml(doc, params[:sheet_url])
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
      already_hash = JSON(last_problems.gsub("collections = ", ""))#ActiveSupport::JSON.decode(().to_json)
    else
      already_hash = {"problems" => {"problem" => []}}
    end
    is_problem_in = collection.update_question_in_collection(already_hash,
      params[:problem_id].to_i, params[:question_id].to_i,
      params[:question_answer], params[:question_analysis], params[:user_answer])
    if is_problem_in == false
      new_col_problem = collection.update_problem_hash(params[:problem_json], params[:paper_id],
        params[:question_answer], params[:question_analysis], params[:user_answer], params[:question_id].to_i)
      already_hash["problems"]["problem"] << new_col_problem
    end
    collection_js = "collections = " + already_hash.to_json.to_s
    path_url = collection.collection_url.split("/")
    collection.generate_collection_url(collection_js, "/" + path_url[1] + "/" + path_url[2], collection.collection_url)

    if params[:exam_user_id]
      exam_user = ExamUser.find(params[:exam_user_id])
      exam_user.update_user_collection(params[:question_id]) if exam_user
    end

    if params[:sheet_url]
      #在sheet中记录小题的收藏状态
      doc = get_doc(params[:sheet_url])
      new_str = "_#{params["problem_index"]}_#{params["question_index"]}"
      collection =doc.root.elements["collection"]
      collection.text.nil? ? collection.add_text(new_str) : collection.text="#{collection.text},#{new_str}"
      write_xml(doc, params[:sheet_url])
    end

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

  def cet4
    #    if cookies[:user_id]
    #      redirect_to "/similarities?category=#{Category::LEVEL_FOUR}"
    #      return false
    #    end
  end

  #oauth登录(四级登录)
  def oauth_login_cet4
    user_info = return_user(params[:access_token])[0]
    @user=User.where("code_id=#{user_info["uid"].to_s} and code_type='renren'").first
    @user=User.create(:code_id=>user_info["uid"],:code_type=>'renren',:name=>user_info["name"],:username=>user_info["name"]) unless @user
    cookies[:user_id]=@user.id
    cookies[:user_name]=@user.username
    redirect_to "/similarities?category=#{Category::LEVEL_FOUR}"
  end

  def return_user(access_token)
    str = "access_token=#{access_token}"
    str << "format=JSON"
    str << "method=xiaonei.users.getInfo"
    str << "v=1.0"
    str << "#{@@secret_key}"
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

  
  
end
