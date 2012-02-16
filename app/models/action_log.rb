# encoding: utf-8
class ActionLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :category
  TYPES = {:LOGIN => 0, :PRACTICE => 1, :EXAM => 2, :RECITE => 3, :STUDY_PLAY => 4}
  #动作类型： 0 登录  1 真题  2 模考  3 背单词  4 学习计划
  TYPE_NAMES = {0 => "登录", 1 => "真题", 2 => "模考", 3 => "背单词", 4 => "学习计划"}

#  def self.return_log_by_types(options={})
#    sql = "select ifnull(sum(total_num), 0) total_num from action_logs "
#    unless options.empty?
#      sql += "where"
#      index = 1
#      options.each { |key, value|
#        sql += " #{key} = #{value} "
#        sql += " and " if options.length != index
#        index += 1
#      }
#    end
#    return ActionLog.find_by_sql(sql)[0]
#  end
#
#  #记录登录时候的action_log
#  def ActionLog.login_log(user_id)
#    action_log = ActionLog.find(:first,
#      :conditions => ["TO_DAYS(NOW())=TO_DAYS(created_at) and types = ? and user_id = ?",
#        ActionLog::TYPES[:LOGIN], user_id.to_i])
#    if action_log
#      action_log.increment!(:total_num, 1)
#    else
#      ActionLog.create(:user_id => user_id, :types => ActionLog::TYPES[:LOGIN],
#        :created_at => Time.now.to_date, :total_num => 1)
#    end
#  end
#
#  #记录模拟考试的log
#  def ActionLog.exam_log(category_id, user_id)
#    action_log = ActionLog.find(:first,
#        :conditions => ["category_id = ? and types = ? and TO_DAYS(NOW())-TO_DAYS(created_at)=0 and user_id = ?",
#          category_id.to_i, ActionLog::TYPES[:EXAM], user_id.to_i])
#      if action_log
#        action_log.increment!(:total_num, 1)
#      else
#        ActionLog.create(:user_id => user_id.to_i, :types => ActionLog::TYPES[:EXAM],
#          :category_id => category_id.to_i, :created_at => Time.now.to_date, :total_num => 1)
#      end
#  end
  
end









