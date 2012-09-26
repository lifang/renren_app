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
  
end
