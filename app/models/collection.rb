# encoding: utf-8
class Collection < ActiveRecord::Base
  belongs_to :user

  require 'rexml/document'
  include REXML
  COLLECTION_PATH = "/collection_datas"

  def set_collection_url(path, url)
    if self.collection_url.nil? || !File.exist?(Constant::PUBLIC_PATH + self.collection_url)
      self.collection_url = self.generate_collection_url("", path, url)
      self.save
    end
  end

  #创建收藏文件
  def generate_collection_url(str, path, url)
    unless File.directory?(Constant::PUBLIC_PATH + COLLECTION_PATH)
      Dir.mkdir(Constant::PUBLIC_PATH + COLLECTION_PATH)
    end
    unless File.directory?(Constant::PUBLIC_PATH + path)
      Dir.mkdir(Constant::PUBLIC_PATH + path)
    end
    f=File.new(Constant::PUBLIC_PATH + url,"w+")
    f.write("#{str.force_encoding('UTF-8')}")
    f.close
    return url
  end

  #更新已经在收藏中的题目
  def update_question_in_collection(collection_hash, problem_id, question_id, answer, analysis, user_answer)
    is_problem_in = false
    collection_hash["problems"]["problem"].each do |problem|
      if problem["id"].to_i == problem_id
        is_problem_in = true
        questions = problem["questions"]["question"]
        if questions.class.to_s == "Hash"
          if questions["id"].to_i == question_id
            questions.merge!({"c_flag" => "1", "answer" => answer, "analysis" => analysis, "user_answer" => user_answer})
            break
          end
        else
          questions.each do |question|
            if question["id"].to_i == question_id
              question.merge!({"c_flag" => "1", "answer" => answer, "analysis" => analysis, "user_answer" => user_answer})
              break
            end
          end unless questions.blank?
        end
        if is_problem_in == true
          break
        end
      end
    end unless collection_hash.empty? or collection_hash["problems"].nil? or collection_hash["problems"]["problem"].blank?
    return is_problem_in
  end

  #修改需要添加的题目
  def update_problem_hash(problem_json, paper_id, answer, analysis, user_answer, question_id)
    new_col_problem = problem_json 
    questions=new_col_problem["questions"]
    new_col_problem.delete("questions")
    new_col_problem.merge!({"paper_id" => paper_id})
    new_col_problem.merge!({"questions" => questions})
    unless new_col_problem["questions"]["question"].nil?
      new_col_questions = new_col_problem["questions"]["question"]
      if new_col_questions.class.to_s == "Hash"
        if new_col_questions["id"].to_i == question_id
          new_col_questions.merge!({"c_flag" => "1", "answer" => answer, "analysis" => analysis, "user_answer" => user_answer})
        end
      else
        new_col_questions.each do |question|
          if question["id"].to_i == question_id
            question.merge!({"c_flag" => "1", "answer" => answer,
                "analysis" => analysis, "user_answer" => user_answer})
            break
          end
        end unless new_col_questions.blank?
      end
    end
    return  new_col_problem
  end
  
  def self.update_collection(user_id, this_problem,problem_id,
      this_question,question_id, paper_id, answer, analysis, user_answer)
    #读取collection.js文件
    collection = Collection.find_or_create_by_user_id(user_id)
    path = Collection::COLLECTION_PATH + "/" + Time.now.to_date.to_s
    url = path + "/#{collection.id}.js"
    collection.set_collection_url(path, url)
    result_url = Constant::PUBLIC_PATH + collection.collection_url
    f = File.open(result_url)
    content = f.read
    resource = (content.nil? or content.strip=="") ? {"problems" => {"problem" => []}} : (JSON (content[13..-1]))
    problems = resource["problems"]["problem"]
    f.close

    #判断是否已经收藏
    problem_exist=false
    question_exist = false
    p_index = -1
    problems.each do |problem|
      p_index += 1
      if problem["id"] == problem_id
        problem_exist = true
        problem["questions"]["question"].each do |question|
          if question["id"] == question_id
            question_exist = true
            break
          end
        end if problem["questions"] && problem["questions"]["question"]
        break
      end
    end

    this_question["answer"]=answer
    this_question["analysis"]=analysis
    this_question["user_answer"]=user_answer
    #收藏新题
    if problem_exist
      unless question_exist        
        if problems[p_index]["questions"]["question"].class.to_s == "Hash"
          problems[p_index]["questions"]["question"] = [problems[p_index]["questions"]["question"], this_question]
        else
          problems[p_index]["questions"]["question"] << this_question
        end        
      end
    else
      problem={}
      problem["id"]=this_problem["id"]
      p_question_type = (this_problem["question_type"].nil? || this_problem["question_type"]=="") ? "0" : this_problem["question_type"]
      problem["question_type"]=p_question_type
      problem["description"]=this_problem["description"]
      problem["title"]=this_problem["title"]
      problem["category"]=this_problem["category"]
      problem["paper_id"] = paper_id
      problem["questions"]={}
      problem["questions"]["question"]=[this_question]
      problems << problem
    end

    #更新collection.js内容
    content = "collections = #{resource.to_json}"
    path_url = collection.collection_url.split("/")
    collection.generate_collection_url(content, "/" + path_url[1] + "/" + path_url[2], collection.collection_url)

  end


  def open_xml
    dir = "#{Rails.root}/public"
    file=File.open(dir + self.collection_url)
    doc=Document.new(file)
    file.close
    return doc
  end

  #添加题目xml
  def add_problem(doc, problem_xml)
    str = doc.to_s.split("<problems/>")
    if doc.elements["collection"].elements["problems"].children.blank?
      doc = str[0] + "<problems>" + problem_xml + "</problems>" + str[1]
    else
      str = doc.to_s.split("</problems>")
      doc = str[0] + problem_xml + "</problems>" + str[1] if str[1]
    end
    return doc
  end

  #删除试题
  def delete_problem(problem_id, doc)
    doc.delete_element("/collection/problems/problem[@id='#{problem_id}']") if doc.elements["/collection/problems/problem[@id='#{problem_id}']"]
    return doc
  end

  #查询试题
  def search(doc, tag, category)
    doc.root.elements["problems"].each_element do |problem|
      if problem.elements["category"].text.to_i != category.to_i
        doc.delete_element(problem.xpath)
      end
    end unless category.nil? or category == ""
    unless tag.nil? or tag == ""
      tags = tag.strip.split(" ")
      doc.root.elements["problems"].each_element do |problem|
        is_include = false
        problem.elements["questions"].each_element do |question|
          if !question.elements["tags"].nil? and !question.elements["tags"].text.nil? and question.elements["tags"].text != ""
            question_tag = question.elements["tags"].text.split(" ")
            tags.each { |t| is_include = true  if question_tag.include?(t) }
          end
          break if is_include
        end
        if is_include == false
          doc.delete_element(problem.xpath)
        end
      end
    end
    return doc
  end


  #自动阅卷保存错题
  def self.auto_add_collection(answer, problem,question,already_hash,block)
    problems=already_hash["problems"]["problem"]
    if problems.class.to_s == "Hash"
      problems=[problems]
    end
    problem=add_problem_mp3(block,problem)
    collection_problem =problem_in_collection(problem,problems,answer,question)
    if collection_problem[0]
      already_hash["problems"]["problem"]=collection_problem[1]
    else
      if !problem.attributes["question_type"].nil? and problem.attributes["question_type"].to_i==Problem::QUESTION_TYPE[:INNER]
        if problem.elements["questions/question[@id=#{question.attributes["id"]}]"].elements["c_flag"].nil?
          problem.elements["questions/question[@id=#{question.attributes["id"]}]"].add_element("c_flag").add_text("1")
        end
        single_question =update_question(answer,question)
      else
        problem.delete_element problem.elements["questions"]
        single_question =update_question(answer,question)
        problem.add_element("questions").add_element(single_question)
      end
      if already_hash["problems"]["problem"].class.to_s == "Hash"
        already_hash["problems"]["problem"]=[already_hash["problems"]["problem"],Hash.from_xml(problem.to_s)["problem"]]
      else
        already_hash["problems"]["problem"] << Hash.from_xml(problem.to_s)["problem"]
      end
    end
    return already_hash
   
  end

  #为大题添加MP3
  def self.add_problem_mp3(block,problem)
    description=block.elements["base_info/description"]
    if !description.nil? and !description.text.nil? and !description.text.index("((mp3))").nil?
      if problem.elements["title"].nil?
        problem.add_element["title"].add_text("((mp3))#{description.text.split("((mp3))")[1]}((mp3))")
      else
        if problem.elements["title"].text.nil?
          problem.elements["title"].text="((mp3))#{description.text.split("((mp3))")[1]}((mp3))"
        elsif problem.elements["title"].text.index("((mp3))").nil?
          problem.elements["title"].text=problem.elements["title"].text+"((mp3))#{description.text.split("((mp3))")[1]}((mp3))"
        end
      end
    end
    return problem
  end
  #当前题目是否已经收藏到错题集
  def self.problem_in_collection(single_problem, collections,answer,question_one)
    has_none=false
    collections.each do |problem|
      if  problem["id"]==single_problem.attributes["id"]
        has_none=true
        questions=problem["questions"]["question"]
        if questions.class.to_s == "Hash"
          questions=[questions]
        end
        question_none=true
        question_one.add_element("c_flag").add_text("1") if !single_problem.attributes["question_type"].nil? and single_problem.attributes["question_type"].to_i==Problem::QUESTION_TYPE[:INNER] and question_one.elements["c_flag"].nil?
        questions.each do |question|
          if question_one.attributes["id"]==question["id"]
            question_none=false
            if question["user_answer"].nil?
              question["repeat_num"]= "1"
              question["error_percent"]= "0"
              question["user_answer"]=[question["user_answer"],answer]
            else
              true_num = (((question["error_percent"].to_i.to_f)/100) * (question["repeat_num"].to_i)).round
              question["repeat_num"] = question["repeat_num"].to_i + 1
              question["error_percent"] = ((true_num.to_f/(question["repeat_num"].to_i))*100).round
              question["user_answer"] << answer
            end
          end
        end
        if question_none
          question =update_question(answer,question_one)
          if problem["questions"]["question"].class.to_s == "Hash"
            problem["questions"]["question"]=[problem["questions"]["question"],Hash.from_xml(question.to_s)["question"]]
          else
            problem["questions"]["question"] << Hash.from_xml(question.to_s)["question"]
          end
        end
        break
      end
    end
    return [has_none,collections]
  end


  #更新当前提点的答案
  def self.update_question(answer_text,que)
    if que.elements["user_answer"].nil?
      true_num = (((que.attributes["error_percent"].to_i.to_f)/100) * (que.attributes["repeat_num"].to_i)).round
      que.attributes["repeat_num"] = que.attributes["repeat_num"].to_i + 1
      que.attributes["error_percent"] = ((true_num.to_f/(que.attributes["repeat_num"].to_i))*100).round
      que.add_element("user_answer").add_text("#{answer_text}")
    else
      que.add_attribute("repeat_num", "1")
      que.add_attribute("error_percent", "0")
    end

    return que
  end


  #错误核对，记录错误答案
  def self.record_user_answer(user_id,problem_id,question_id,user_answer)
    collection = Collection.find_or_create_by_user_id(user_id)
    path =  COLLECTION_PATH + "/" + Time.now.to_date.to_s
    collection_url = path + "/#{collection.id}.js"
    collection.set_collection_url(path, collection_url)
    file =  File.open("#{Rails.root}/public#{collection.collection_url}")
    last_problems = file.readlines.join
    unless last_problems.nil? or last_problems.strip == ""
      collections = JSON(last_problems.gsub("collections = ", ""))#ActiveSupport::JSON.decode(().to_json)
    end
    file.close
    problems=collections["problems"]["problem"]
    if problems.class.to_s != "Array"
      problems=[problems]
    end
    problems.each do |problem|
      if problem["id"].to_i==problem_id
        questions=problem["questions"]["question"]
        if questions.class.to_s != "Array"
          questions=[questions]
        end
        questions.each do |question|
          if question["id"].to_i==question_id
            if question["user_answer"].class.to_s == "Array"
              question["user_answer"] << user_answer
            else
              question["user_answer"]=[user_answer]
            end
          end
        end
      end
    end
    collection_js="collections = " + collections.to_json.to_s
    path_url = collection.collection_url.split("/")
    collection.generate_collection_url(collection_js, "/" + path_url[1] + "/" + path_url[2], collection.collection_url)
  end

end
