#encoding: utf-8
class Paper < ActiveRecord::Base
  has_many :examination_paper_relations,:dependent=>:destroy
  has_many :examinations, :through=>:examination_paper_realations, :source => :examination
  belongs_to :user,:foreign_key=>"creater_id"
  belongs_to :category
  has_many :exam_users

  default_scope :order => "papers.created_at desc"

end
