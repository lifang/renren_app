# encoding: utf-8
class Collection < ActiveRecord::Base
  belongs_to :user

#  require 'rexml/document'
#  include REXML
  COLLECTION_PATH = "/collections"

  def set_collection_url(path, url)
    if self.collection_url.nil? || !File.exist?(Constant::PUBLIC_PATH + self.collection_url)
      self.collection_url = self.generate_collection_url("", path, url)
      self.save
    end
  end
  
  #创建收藏文件
  def generate_collection_url(str, path, url)
    unless File.directory?(Constant::PUBLIC_PATH + "/collections")
      Dir.mkdir(Constant::PUBLIC_PATH + "/collections")
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
    new_col_problem = ActiveSupport::JSON.decode((JSON(problem_json)).to_json)
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


end
