# encoding: utf-8
module Constant

  #赶考网链接
  #GANKAO_URL = "http://localhost:3001"

  #BACK_SERVER_PATH = "http://localhost:3000"
  #SERVER_PATH = "http://localhost:3002"

  GANKAO_URL = "http://127.0.0.1:3001"
  BACK_SERVER_PATH = "http://127.0.0.1:3000" #需修改
  SERVER_PATH = "http://127.0.0.1:3001"

  #项目文件目录(使用赶考前台的public目录)
  PUBLIC_PATH = "e:/gankao_season2/public"

  #后台项目文件目录
  BACK_PUBLIC_PATH = "e:/exam_season2/public"

  #充值vip有效期
  DATE_LONG={:vip=>90,:trail=>7} #试用七天

  #设置通过分享获得会员的数量限制(每日)
  RENREN_ORDERS_SUM = {:cet_4=>50,:cet_6=>25}
  SINA_ORDERS_SUM = {:cet_4=>50,:cet_6=>25}
  BAIDU_ORDERS_SUM = {:cet_4=>150,:cet_6=>125}
  #人人公共主页id
  RENREN_ID = 600942099

  #qq appid
  APPID="223448"
  #分享图片路径
  IMG_URL=SERVER_PATH+"/share_logo.png"
  #四六级抢名额
  FREE_QQ_COUNT = {:cet_4=>10,:cet_6=>10}
  #六级分享图片
  IMG_URL_6=SERVER_PATH+"/share_logo_6.png"
end
