#encoding: utf-8
class Category < ActiveRecord::Base
  #  has_many :problems
  #  has_many :papers
  #  has_many :examinations
  #  has_many :user_category_relations,:dependent=>:destroy
  #  has_many :users, :through=>:user_category_relations, :source => :user
  #  has_many :category_manages
  #  has_one :study_plan
  #  has_many :notices
  #  has_many :words
  #  # 判断分类是否存在
  #  TYPES = {"2" => "english_fourth_level", "3" => "english_sixth_level"}   # :FOURTH_LEVEL 四级； :SIXTH_LEVEL 六级
  #  TYPE_IDS = {:english_fourth_level => 2, :english_sixth_level => 3} # :FOURTH_LEVEL 四级； :SIXTH_LEVEL 六级
  LEVEL_FOUR = 2
  LEVEL_SIX = 3
  KAO_YAN = 4
  NAME ={"2"=>"英语四级","3"=>"英语六级","4"=>"考研英语"}

  CET={2=>"(2006.12-2012.6)",3=>"(2006.12-2012.6)",4=>"(2008.12-2012.6)"}
end