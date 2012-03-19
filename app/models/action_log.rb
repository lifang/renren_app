# encoding: utf-8
class ActionLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :category
  TYPES = {:LOGIN => 0, :PRACTICE => 1, :EXAM => 2, :RECITE => 3, :STUDY_PLAY => 4}
  #动作类型： 0 登录  1 真题  2 模考  3 背单词  4 学习计划
  TYPE_NAMES = {0 => "登录", 1 => "真题", 2 => "模考", 3 => "背单词", 4 => "学习计划"}

  #记录登录时候的action_log
  def ActionLog.login_log(user_id)
    action_log = ActionLog.find(:first,
      :conditions => ["TO_DAYS(NOW())=TO_DAYS(created_at) and types = ? and user_id = ?",
        ActionLog::TYPES[:LOGIN], user_id.to_i])
    if action_log
      action_log.increment!(:total_num, 1)
    else
      ActionLog.create(:user_id => user_id, :types => ActionLog::TYPES[:LOGIN],
        :created_at => Time.now.to_date, :total_num => 1)
    end
  end
  
end









