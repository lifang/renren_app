# encoding: utf-8
class UserWordRelation < ActiveRecord::Base

  STATUS = {:NOMAL => 0, :RECITE => 1} #0 未背诵 1 已背诵

  def self.user_words(user_id)
    return UserWordRelation.count(:id, :conditions => ["user_id = ? and status = #{STATUS[:NOMAL]}", user_id])
  end

    #用户刚开始练习单词之前给每个用户初始化一条记录
  def self.single_user_word(user_id, category_id)
    user_word_relation = UserWordRelation.find_by_user_id_and_category_id(user_id, category_id)
    if user_word_relation.nil?
      ids_arr = []
      word_ids = Word.find_by_sql(["select w.id w_id from words w where w.level < #{Word::WORD_LEVEL[:THIRD]}
        and w.category_id = ?", category_id])
      unless word_ids.blank?
        word_ids.each { |w| ids_arr << w.w_id }
      end
      user_word_relation = UserWordRelation.create(:user_id => user_id,
        :nomal_ids => ids_arr.join(","), :category_id => category_id)
    end
    return user_word_relation
  end



  #用户增加背诵的单词
  def self.add_nomal_ids(user_id, word_id, category_id)
    user_word_relation = UserWordRelation.single_user_word(user_id, category_id)
    nomal_ids = ""
    if user_word_relation.nomal_ids.nil?
      nomal_ids = word_id
    else
      nomal_ids = ( ["#{word_id}"] | (user_word_relation.nomal_ids.split(","))).join(",")
    end
    user_word_relation.update_attributes(:nomal_ids => nomal_ids)
  end
  
end
