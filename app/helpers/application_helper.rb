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
      orders = Order.find(:all, :conditions => ["user_id = ? and status = ?", user_id.to_i , STATUS[:NOMAL] ])
      orders.each do |order|
        if order.types == Order::TYPES[:CHARGE] or order.types == Order::TYPES[:OTHER] or order.types == Order::TYPES[:ACCREDIT] or order.types == Order::TYPES[:RENREN]
          this_order = "#{order.category_id}=#{Order::USER_ORDER[:VIP]}"
          cookies[:user_role] = cookies[:user_role].empty? ? this_order : (cookies[:user_role] + "&" + this_order)
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
    unless cookies[:user_role] =~ /#{category_id}/
      order=Order.create(:user_id => user_id, :types => Order::TYPES[:TRIAL_SEVEN],
        :status => Order::STATUS[:NOMAL], :start_time => Time.now.to_datetime, :total_price => 0,
        :end_time => Time.now.to_datetime + Constant::DATE_LONG[:trail].days,
        :category_id => category_id, :remark => Order::TYPE_NAME[Order::TYPES[:TRIAL_SEVEN]])
      this_order = "#{category_id}=#{Order::USER_ORDER[:TRIAL]}"
      cookies[:user_role] = cookies[:user_role].empty? ? this_order : (cookies[:user_role] + "&" + this_order)
    end
  end

  #判断有没有当前分类的权限
  def category_role(category_id)
    current_role = Order::USER_ORDER[:NOMAL]
    user_role?(cookies[:user_id]) if cookies[:user_role].nil?
    all_category = cookies[:user_role].split("&")
    all_category.each do |category|
      if category =~ /#{category_id}/
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
  

end
