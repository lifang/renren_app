# encoding: utf-8
module ApplicationHelper


  def deny_access
    redirect_to "/logins?last_url=#{request.url}"
  end

  def signed_in?
    return cookies[:user_id] != nil
  end

  # 中英文混合字符串截取
  def truncate_u(text, length = 30, truncate_string = "......")
    l=0
    char_array=text.unpack("U*")
    char_array.each_with_index do |c,i|
      l = l+ (c<127 ? 0.5 : 1)
      if l>=length
        return char_array[0..i].pack("U*")+(i<char_array.length-1 ? truncate_string : "")
      end
    end
    return text
  end

  #判断是否vip、试用用户或普通用户
  def user_role?(user_id)
    if cookies[:user_role].nil?
      cookies[:user_role] = {:value => "", :path => "/", :secure  => false}
      cookies[:must] = {:value =>nil, :path => "/", :secure  => false}
      orders = Order.find(:all, :conditions => ["user_id = ? and status = #{Order::STATUS[:NOMAL]}", user_id.to_i])
      orders.each do |order|
        if order.types == Order::TYPES[:MUST] or order.types == Order::TYPES[:SINA] or order.types == Order::TYPES[:RENREN] or
            order.types == Order::TYPES[:ACCREDIT] or order.types == Order::TYPES[:CHARGE] or order.types == Order::TYPES[:OTHER]
          this_order = "#{order.category_id}=#{Order::USER_ORDER[:VIP]}"
          cookies[:user_role] = cookies[:user_role].empty? ? this_order : (cookies[:user_role] + "&" + this_order)
          cookies[:must]= cookies[:must].nil? ? "#{order.category_id}=" : (cookies[:must] + "&#{order.category_id}=") if order.types == Order::TYPES[:MUST]
        elsif order.types == Order::TYPES[:TRIAL_SEVEN]
          if order.end_time < Time.now or order.status == false
            this_order = "#{order.category_id}=#{Order::USER_ORDER[:NOMAL]}"
            order.update_attributes(:status => Order::STATUS[:INVALIDATION]) if order.status != false
          else
            this_order = "#{order.category_id}=#{Order::USER_ORDER[:TRIAL]}"
          end
          cookies[:user_role] = cookies[:user_role].empty? ? this_order : (cookies[:user_role] + "&" + this_order)
        end
      end unless orders.blank?
    end
  end

  #如果当前科目没有付费记录，则记录一条新的记录
  def user_order(category_id, user_id)
    user_role?(user_id) if cookies[:user_role].nil?
    unless cookies[:user_role].include?("#{category_id}=")
      order = Order.find(:first, :conditions => ["user_id = ? and category_id = ? and status = #{Order::STATUS[:INVALIDATION]}",
          user_id.to_i, category_id.to_i])
      if order
        this_order = "#{category_id}=#{Order::USER_ORDER[:NOMAL]}"
      else
        Order.create(:user_id => user_id, :types => Order::TYPES[:TRIAL_SEVEN],
        :status => Order::STATUS[:NOMAL], :start_time => Time.now.to_datetime, :total_price => 0,
        :end_time => Time.now.to_datetime + Constant::DATE_LONG[:trail].days,
        :category_id => category_id, :remark => Order::TYPE_NAME[Order::TYPES[:TRIAL_SEVEN]])
      this_order = "#{category_id}=#{Order::USER_ORDER[:TRIAL]}"
      end
      cookies[:user_role] = cookies[:user_role].empty? ? this_order : (cookies[:user_role] + "&" + this_order)
    end
  end

  #判断有没有当前分类的权限
  def category_role(category_id)
    current_role = Order::USER_ORDER[:NOMAL]
    user_role?(cookies[:user_id]) if cookies[:user_role].nil?
    all_category = cookies[:user_role].split("&")
    all_category.each do |category|
      if category.include?("#{category_id}=")
        current_role = category.split("=")[1]
      end
    end unless all_category.blank?
    return current_role.to_i
  end

  #判断是否vip
  def is_vip?(category_id)
    return category_role(category_id) == Order::USER_ORDER[:VIP]
  end

  #判断是否试验用
  def is_trial?(category_id)
    return category_role(category_id) == Order::USER_ORDER[:TRIAL]
  end

  #是否普通用户
  def is_nomal?(category_id)
    return category_role(category_id) == Order::USER_ORDER[:NOMAL]
  end


  
  #START -----人人API
  #人人主方法
  def renren_api(request)
    uri = URI.parse("http://api.renren.com")
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request(request).body
  end
  #
  #构成人人签名请求
  def renren_sig_request(query,secret_key)
    str = ""
    query.sort.each{|key,value|str<<"#{key}=#{value}"}
    str<<secret_key
    sig = Digest::MD5.hexdigest(str)
    query[:sig]=sig
    request = Net::HTTP::Post.new("/restserver.do")
    request.set_form_data(query)
    return request
  end
  #
  #人人获取用户信息
  def renren_get_user(access_token,secret_key)
    query = {:access_token => access_token,:format => 'JSON',:method => 'xiaonei.users.getInfo',:v => '1.0'}
    request = renren_sig_request(query,secret_key)
    response = JSON renren_api(request)
  end
  #
  #人人发送新鲜事
  def renren_send_message(access_token,message,secret_key)
    query = {:access_token => "#{access_token}",:comment=>"#{message}",:format => 'JSON',:method => 'share.share',:type=>"6",:url=>"http://www.gankao.co",:v => '1.0'}
    request = renren_sig_request(query,secret_key)
    response =JSON renren_api(request)
  end
  #
  #END -------人人API----------


  
  #START -------开心网API----------
  #
  #开心主方法
  def kaixin_api(request)
    uri = URI.parse("https://api.kaixin001.com")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request(request).body
  end
  #
  #开心获取accesstoken
  def kaixin_accesstoken(code)
    request = Net::HTTP::Get.new("/oauth2/access_token?grant_type=authorization_code&code=#{code}&client_id=#{Constant::KAIXIN_API_KEY}&client_secret=#{Constant::KAIXIN_API_SECRET}&redirect_uri=#{Constant::SERVER_PATH}/logins/respond_kaixin")
    response = JSON kaixin_api(request)
  end
  #
  #开心获取用户信息
  def kaixin_get_user(access_token)
    request = Net::HTTP::Get.new("/users/me.json?access_token=#{access_token}")
    response = JSON kaixin_api(request)
  end
  #
  #开心网添加记录
  def kaixin_send_message(access_token,message)
    url="https://api.kaixin001.com"
    info=create_post_http(url,"/records/add.json",{:access_token=>access_token,:content=>message})
    if info["rid"].nil?
      p "kaixin error code - #{info["error"]}"
    else
      p "kaixin user-record id is  #{info["rid"]}"
    end
  end
  #
  #构造post请求
  def create_post_http(url,route_action,params)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(route_action)
    request.set_form_data(params)
    return JSON http.request(request).body
  end
  #
  #END -------开心网API----------


  
  #START -------新浪微博API----------
  #
  #新浪微博主方法
  def sina_api(request)
    uri = URI.parse("https://api.weibo.com")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.request(request).body
  end
  #
  #新浪微博获取用户信息
  def sina_get_user(access_token,uid)
    request = Net::HTTP::Get.new("/2/users/show.json?access_token=#{access_token}&uid=#{uid}")
    response = JSON sina_api(request)
  end
  #
  #新浪微博发送微博
  def sina_send_message(access_token,message)
    request = Net::HTTP::Post.new("/2/statuses/update.json")
    request.set_form_data({"access_token" =>access_token, "status" => message})
    response =JSON sina_api(request)
  end
  #
  #新浪微博发送带图片的微博
  def sina_send_pic(access_token,message,pic)
    request = Net::HTTP::Post.new("/2/statuses/upload.json")
    request.set_form_data({"access_token" =>access_token, "status" => message ,"pic" => pic})
    response =JSON sina_api(request)
  end
  #END -------新浪微博API----------

end
