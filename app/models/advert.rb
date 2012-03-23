# encoding: utf-8
class Advert < ActiveRecord::Base
  belongs_to :region

  def self.ip_advert(ips)
    unless ips.nil?
      true_ip=0
      ips.split(".").each_with_index {|ip,index|  true_ip +=(ip.to_i)*(256**(3-index))}
      ip_t=IpTable.first(:conditions=>["start_at<=? and end_at >= ?",true_ip,true_ip])
    end
    sql="select a.content from adverts a inner join regions r on r.id=a.region_id inner join regions re on re.id=r.parent_id where 1=1"
    unless ip_t.nil?
      unless  ip_t.city_name.nil?
        sql += " and r.name='#{ip_t.city_name}' order by a.created_at desc "
      else
        sql += " and re.name='#{ip_t.province_name}' order by a.created_at desc "
      end
    else
      sql += " order by a.created_at desc  limit 10"
    end
    return Advert.find_by_sql(sql)
  end

end