# encoding: utf-8
class Examination < ActiveRecord::Base
  has_many :examination_paper_relations,:dependent => :destroy
  has_many :papers,:through=>:examination_paper_relations, :source => :paper
  belongs_to :user,:foreign_key=>"creater_id"
  has_many :exam_users,:dependent => :destroy
#  has_many :examination_tag_relations,:dependent => :destroy
#  has_many :tags,:through=>:examination_tag_relations, :source => :tag
#
#  STATUS = {:EXAMING => 0, :LOCK => 1, :GOING => 2,  :CLOSED => 3 } #考试的状态：0 考试中 1 未开始 2 进行中 3 已结束
#  IS_PUBLISHED = {:NEVER => 0, :ALREADY => 1} #是否发布  0 没有 1 已经发布
#  IS_FREE = {:YES => 1, :NO => 0} #是否免费 1是 0否
#
  TYPES = {:SIMULATION => 0, :OLD_EXAM => 1, :PRACTICE => 2, :SPECIAL => 3}
#  #考试的类型： 0 模拟考试  1 真题练习  2 综合训练  3 专项练习
#  TYPE_NAMES = {0 => "模拟考试", 1 => "真题练习", 2 => "综合训练", 3 => "专项练习"}
#
#  default_scope :order => "examinations.created_at desc"
#
#  #显示单个登录考生能看到的所有的考试
#  def Examination.return_examinations(user_id, examination_id = nil)
#    sql = "select e.*, eu.id exam_user_id, eu.paper_id, eu.started_at, eu.ended_at, eu.is_submited from examinations e
#          left join exam_users eu on e.id = eu.examination_id
#          where e.is_published = #{IS_PUBLISHED[:ALREADY]} and e.status != #{STATUS[:CLOSED]} #"
#    sql += " and e.id = #{examination_id} " if !examination_id.nil? and examination_id != ""
#    sql += " and eu.user_id = #{user_id} "
#    Examination.find_by_sql(sql)
#  end



end
