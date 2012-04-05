#encoding: utf-8
class User < ActiveRecord::Base
  has_one :user_action_log
  has_many :user_plan_relations,:dependent => :destroy
  has_one :collection

  attr_accessor :password
  validates:password, :confirmation=>true,:length=>{:within=>6..20}, :allow_nil => true

  FROM = {"sina" => "新浪微博", "renren" => "人人网", "qq" => "腾讯网"}
  TIME_SORT = {:ASC => 0, :DESC => 1}   #用户列表按创建时间正序倒序排列
  U_FROM = {:WEB => 0, :APP => 1} #注册用户来源，0 网站   1 应用
  USER_FROM = {0 => "网站" , 1 => "应用"}

  DEFAULT_PASSWORD = "123456"


  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end
  
  def encrypt_password
    self.encrypted_password=encrypt(password)
  end

  private
  def encrypt(string)
    self.salt = make_salt if new_record?
    secure_hash("#{salt}--#{string}")
  end

  def make_salt
    secure_hash("#{Time.new.utc}--#{password}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end

end

