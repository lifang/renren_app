# encoding: utf-8
class ExaminationPaperRelation< ActiveRecord::Base
  belongs_to:examination
  belongs_to:paper

  DEFAULT = {:YES => 1, :NO => 0} #是否是默认的，1 是， 0 不是
end
