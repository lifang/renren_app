# encoding: utf-8
class ExamUser < ActiveRecord::Base
  belongs_to :user
  #has_many :rater_user_relations,:dependent=>:destroy
  belongs_to :examination
  #has_many :exam_raters,:through=>:rater_user_relations,:foreign_key=>"exam_rater_id"
  belongs_to :paper
#  require 'rexml/document'
#  include REXML
#  require 'spreadsheet'

  IS_SUBMITED = {:YES => 1, :NO => 0} #用户是否提交 1 提交 2 未提交
  IS_USER_AFFIREMED = {:YES => 1, :NO => 0} #用户是否确认  1 已确认 0 未确认
  default_scope :order => "exam_users.total_score desc"

  #检验当前当前考生是否能考本场考试
#  def self.can_answer(user_id, examination_id)
#    str = ""
#    examination = Examination.return_examinations(user_id, examination_id)
#    if examination.any?
#      if !examination[0].is_submited.nil? and (examination[0].is_submited == true or examination[0].is_submited == 1)
#        str = "您已经交卷。"
#      else
#        if examination[0].paper_id.nil? and examination[0].start_at_time > Time.now
#          str = "本场考试开始时间为#{examination[0].start_at_time.strftime("%Y-%m-%d %H:%M:%S")},请您做好准备。"
#        elsif (!examination[0].start_end_time.nil? and examination[0].start_end_time < Time.now) or
#            examination[0].status == Examination::STATUS[:CLOSED]
#          str = "本场考试已经结束。"
#        end if examination[0].start_at_time
#      end
#    else
#      str = "本场考试已经取消，或者您没有资格参加本场考试。"
#    end
#    return [str, examination]
#  end
#
#  #考生更新考试时长信息
#  def update_info_for_join_exam
#    self.toggle!(:is_user_affiremed)
#    self.started_at = Time.now
#    self.ended_at = Time.now + self.paper.time.minutes if self.paper.time
#    self.answer_sheet_url = self.generate_answer_sheet_url(self.create_answer_xml, "result")
#    self.save
#  end
#
#  #随机分配学生一张试卷
#  def set_paper(examination)
#    papers = examination.papers
#    self.paper = papers[rand(papers.length-1)]
#    self.save
#  end
#
#  #生成考生文件
#  def generate_answer_sheet_url(str, path)
#    dir = "#{Rails.root}/public/" + path + "/#{self.examination_id}"
#    unless File.directory?(dir)
#      Dir.mkdir(dir)
#    end
#    file_name = "/#{self.id}.xml"
#    url = dir + file_name
#    f = File.new(url,"w+")
#    f.write("#{str.force_encoding('UTF-8')}")
#    f.close
#    return "/" + path + "/#{self.examination_id}" + file_name
#  end
#
#  #创建考生答卷
#  def create_answer_xml(options = {})
#    content = "<?xml version='1.0' encoding='UTF-8'?>"
#    content += <<-XML
#      <exam id='#{self.examination_id}'>
#        <paper id='#{self.paper_id}' score='0'>
#          <questions></questions>
#          <auto_score></auto_score>
#          <rate_score></rate_score>
#          <blocks></blocks>
#          <collections></collections>
#        </paper>
#      </exam>
#    #XML
#    options.each do |key, value|
#      content+="<#{key}>#{value.force_encoding('ASCII-8BIT')}</#{key}>"
#    end unless options.empty?
#    return content
#  end
#
#  def open_xml
#    dir = "#{Rails.root}/public"
#    url = File.open(dir + self.answer_sheet_url)
#    doc=Document.new(url)
#    url.close
#    return doc
#  end
#
#  def update_answer_url(doc, question_ids_options = {}, block_id = nil)
#    questions = doc.root.elements["paper/questions"]
#    questions.each_element { |q| doc.delete_element(q.xpath) }if questions.children.any?
#    question_ids_options.each do |key, value|
#      question = questions.add_element("question")
#      question.add_attribute("id","#{key}")
#      question.add_attribute("score","0")
#      answer = value[0].nil? ? "" : value[0].strip
#      is_sure = value[1].nil? ? "" : value[1].strip
#      question.add_element("answer").add_text("#{answer}")
#      question.add_attribute("is_sure", "#{is_sure}")
#    end unless question_ids_options == {}
#    unless block_id.nil?
#      block_ids = block_id.split(",")
#      blocks = doc.root.elements["paper/blocks"]
#      unless blocks.nil?
#        blocks.each_element { |b| doc.delete_element(b.xpath) }if blocks.children.any?
#        block_ids.each do |b_id|
#          block = blocks.add_element("block")
#          block.add_attribute("id","#{b_id}")
#          block.add_attribute("score","0")
#        end
#      end
#    end
#    return doc.to_s
#  end
#
#  def submited!
#    self.is_submited=1
#    self.save
#  end
#
#  #更新用户文件中的收藏
#  def update_user_collection(question_id)
#    doc = self.open_xml
#    collection_ids = doc.root.elements["paper/collections"].text
#    unless collection_ids.nil? or collection_ids.empty?
#      ids = collection_ids.split(",")
#      ids << question_id unless ids.include?(question_id)
#      doc.root.elements["paper/collections"].text = ids.join(",")
#    else
#      doc.root.elements["paper/collections"].add_text(question_id)
#    end
#    self.generate_answer_sheet_url(doc.to_s, "result")
#  end
#
#  #统计各部分的分数
#  def part_score
#    part_score_arr = []
#    answer_xml = self.open_xml
#    scores = answer_xml.get_elements("//blocks/block")
#    if scores[2].nil? or scores[2].attributes["score"].nil? or scores[2].attributes["score"].to_i == 0
#      part_score_arr << 0
#    elsif scores[2].attributes["score"].to_f*10%10 == 0
#      part_score_arr << scores[2].attributes["score"].to_i
#    elsif scores[2].attributes["score"].to_f*10%10 <= 5
#      part_score_arr << (scores[2].attributes["score"].to_f*10/10).to_f + 0.5
#    else
#      part_score_arr << (scores[2].attributes["score"].to_f*10/10).round
#    end
#
#    second_score = (scores[1].nil? ? 0 :scores[1].attributes["score"].to_f) +
#      (scores[3].nil? ? 0 :scores[3].attributes["score"].to_f)
#    if second_score.to_f*10%10 == 0
#      part_score_arr << second_score.to_i
#    elsif second_score.to_f*10%10 <= 5
#      part_score_arr << (second_score.to_f*10/10).to_f + 0.5
#    else
#      part_score_arr << (second_score.to_f*10/10).round
#    end
#
#    if scores[4].nil? or scores[4].attributes["score"].nil? or scores[4].attributes["score"].to_i == 0
#      part_score_arr << 0
#    elsif scores[4].attributes["score"].to_f*10%10 == 0
#      part_score_arr << scores[4].attributes["score"].to_i
#    elsif scores[4].attributes["score"].to_f*10%10 <= 5
#      part_score_arr << (scores[4].attributes["score"].to_f*10/10).to_f + 0.5
#    else
#      part_score_arr << (scores[4].attributes["score"].to_f*10/10).round
#    end
#
#    forth_score = (scores[0].nil? ? 0 :scores[0].attributes["score"].to_f) +
#      (scores[5].nil? ? 0 :scores[5].attributes["score"].to_f)
#    if forth_score.to_f*10%10 == 0
#      part_score_arr << forth_score.to_i
#    elsif forth_score.to_f*10%10 <= 5
#      part_score_arr << (forth_score.to_f*10/10).to_f + 0.5
#    else
#      part_score_arr << (forth_score.to_f*10/10).round
#    end
#    return part_score_arr
#  end

end
