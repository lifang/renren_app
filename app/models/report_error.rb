#encoding: utf-8
class ReportError < ActiveRecord::Base
 
  ERROR_TYPE = {1=>"题目错误",2=>"答案错误",3=>"解析错误",4=>"词汇错误"}
  TYPE={:TOPOIC=>1,:ANSWER=>2,:ANALISIS=>3,:WORD=>4}  #1 题目错误； 2 答案错误；3 解析错误; 4 词汇错误
  STATUS={:UNSOVLED=>0,:OVER=>1,:IGNORE=>2} #0 未解决 1 解决 2忽略
end
