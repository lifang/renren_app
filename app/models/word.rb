#encoding: utf-8
class Word < ActiveRecord::Base
  
  belongs_to :category
  has_many :word_sentences
  has_many :word_question_relations,:dependent=>:destroy
  has_many :questions,:through=>:word_question_relations, :source => :question
  has_many :word_discriminate_relations,:dependent => :destroy
  has_many :discriminates,:through=>:word_discriminate_relations, :source => :discriminate  

  TYPES = {0 => "n.", 1 => "v.", 2 => "pron.", 3 => "adj.", 4 => "adv.",
    5 => "num.", 6 => "art.", 7 => "prep.", 8 => "conj.", 9 => "interj.", 10 => "u = ", 11 => "c = ", 12 => "pl = "}
  #英语单词词性 名词 动词 代词 形容词 副词 数词 冠词 介词 连词 感叹词 不可数名词 可数名词 复数
  WORD_LEVEL = {:FIRST => 1, :SECOND => 2, :THIRD => 3, :FOURTH => 4, :FIFTH => 5, :SIXTH => 6, :SEVENTH => 7,
    :EIGHTH => 8, :NINTH => 9, :TENTH => 10}
  LEVEL = {1 => "一", 2 => "二", 3 => "三", 4 => "四", 5 => "五", 6 => "六",
    7 => "七", 8 => "八", 9 => "九", 10 => "十"}  #单词的等级

  def self.recite_words
    return Word.count('id', :conditions => "level < #{WORD_LEVEL[:THIRD]}")
  end

  def self.current_recite_words(user_id, category_id, start_column, type)
    return_word = []
    if type == "new"
      words = UserWordRelation.find_by_sql(["select * from user_word_relations uwr
      inner join words w on w.id = uwr.word_id where w.category_id = ? 
      and uwr.status = #{UserWordRelation::STATUS[:NOMAL]}
      and uwr.user_id = ? limit 20", category_id, user_id])
      if words.blank? or words.length < 20
        other_length = 20 - words.length
        other_words = Word.find(:all,
          :conditions => ["id not in (select uwr.word_id from user_word_relations uwr where uwr.user_id = ?)
         and category_id = ? and level < #{Word::WORD_LEVEL[:THIRD]} ",category_id, user_id],
          :limit => other_length, :order => "id", :offset => start_column)
      end
      return_word = other_words.nil? ? words : (words + other_words)
    else
      words = UserWordRelation.find_by_sql(["select * from user_word_relations uwr
      inner join words w on w.id = uwr.word_id where w.category_id = ?
      and uwr.status = #{UserWordRelation::STATUS[:RECITE]}
      and uwr.user_id = ?", category_id, user_id])
      other_words = Word.find(:all,
        :conditions => ["id not in (select uwr.word_id from user_word_relations uwr where uwr.user_id = ?)
         and category_id = ? and level < #{Word::WORD_LEVEL[:THIRD]} ",category_id, user_id],
        :limit => start_column, :order => "id")
      all_word = words.nil? ? other_words : (words + other_words)
      if all_word.length > 20
        chars = (1..all_word.length).to_a
        code_array = []
        1.upto(20) {code_array << chars[rand(chars.length)]}
        code_array.each { |c| return_word << all_word[c] }
      else
        return_word = all_word
      end      
    end
    return return_word
  end

  def self.all_sentences(sentence_hash, word_ids)
    word_sentences = WordSentence.find(:all, :conditions => ["word_id in (?)", word_ids])
    word_sentences.each { |sentence|
      if sentence_hash[sentence.word_id].nil?
        sentence_hash[sentence.word_id] = [sentence.description]
      else
        sentence_hash[sentence.word_id] << sentence.description
      end
    }
    return sentence_hash
  end

end
