# encoding: utf-8
class Order< ActiveRecord::Base
  belongs_to :user
  STATUS = {:NOMAL => 1, :INVALIDATION => 0} #1 正常  0 失效
  TYPES = {:CHARGE => 1, :OTHER => 0,:TRIAL_SEVEN => 2, :ACCREDIT => 3,:COMPETE => 4,:RENREN => 5} #1 付费  0 其它 2 七天试用
  TYPE_NAME = {1 => "付费", 0 => "其它",2=>"七天试用",3=>"授权码",4=>"模考大赛",5=>"人人分享"}
  USER_ORDER = {:VIP => 0, :TRIAL => 1, :NOMAL => 2} #根据order类型和状态判断当前用户的情况：0 vip  1 试用用户  2 普通用户
end
