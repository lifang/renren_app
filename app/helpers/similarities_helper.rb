# encoding: utf-8
module SimilaritiesHelper

  require 'net/http'
  require "uri"
  require 'openssl'

  #qq登录参数
  REQUEST_URL_QQ="https://graph.qq.com/oauth2.0/authorize"
  #请求openId
  REQUEST_OPENID_URL="https://graph.qq.com/oauth2.0/me"
  #请求详参
  APPID="223448"
  REQUEST_ACCESS_TOKEN={
    :response_type=>"token",
    :client_id=>APPID,
    :redirect_uri=>"#{Constant::SERVER_PATH}/similarities/back_qq",
    :scope=>"get_user_info,add_topic",
    :state=>"1"
  }

  REQUEST_ACCESS_TOKEN_6={
    :response_type=>"token",
    :client_id=>APPID,
    :redirect_uri=>"#{Constant::SERVER_PATH}/similarities/back_qq_6",
    :scope=>"get_user_info,add_topic",
    :state=>"1"
  }

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


  #构造get请求
  def create_get_http(url,route)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request= Net::HTTP::Get.new(route)
    back_res =http.request(request)
    return JSON back_res.body
  end

end
