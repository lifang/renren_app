# encoding: utf-8
class UserWordRelation < ActiveRecord::Base

 STATUS = {:NOMAL => 0, :RECITE => 1} #0 未背诵 1 已背诵

  def self.user_words(user_id)
    return UserWordRelation.count(:id, :conditions => ["user_id = ? and status = #{STATUS[:NOMAL]}", user_id])
  end

end
