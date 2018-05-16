module Wechat
  module WeixinHelper
  	def parcel_status_desc(status)
  		{"pdf_processing"=>"创建面单中","pdf_failure"=>"创建面单失败","initialized"=>"创建成功","in-process"=>"处理中","in-process_printed"=>"进行中_面单已打印","blocked"=>"被拦截","closed"=>"已关闭","cancelled"=>"已取消","applying-for-cancellation"=>"申请取消"}[status]
  	end
  	def shpmt_status_desc(status)
  		{'initialized'=>'创建完成','returned'=>'入库处理中','on-the-way'=>'运输途中','delivering'=>'投递中','sorted'=>'上网','sent-back'=>'被退回','arrived'=>'已送达'}[status]
  	end
  	def pmnt_status_desc(status)
  		{'unpaid'=>'未支付','paid'=>'已支付','need-extra-money'=>'需补款','abnormally-paid'=>'已补款','paid-pending'=>'支付中'}[status]
  	end
  	def parcel_carrier_desc(type)
  		{"EMS"=>"EMS","DHL"=>"DHL","POSTNL"=>"POSTNL","YTO"=>"YTO","GEO"=>"GEO","Yodel"=>"Yodel","IAA"=>"IAA","CZ_POST"=>"CZ_POST","Royal"=>"Royal","Pilot"=>"Pilot"}[type]
  	end
             def max_in_status_desc(status)
                        {'returned'=>'入库处理中','on-the-way'=>'运输途中','delivering'=>'投递中','sorted'=>'上网','arrived'=>'已送达','sent-back'=>'被退回', 'initialized'=>'创建成功','pdf_processing'=>'创建面单中','pdf_failure'=>'创建面单失败', 'in-process'=>'处理中','in-process_printed'=>'进行中_面单已打印','blocked'=>'被拦截','applying-for-cancellation'=>'申请取消','closed'=>'已关闭','cancelled'=>'已取消','wait_id_img'=>'身份证资料处理中'}[status]
            end
            def tracking_info_analysis(time,tracking_info)
                        Rails.logger.info("weixin_helper tracking_info: #{tracking_info}")
                        match_info=tracking_info[0,30].match(/(\d.*):(.*)/)
                        if match_info.present?&&Time.parse(match_info[1]).present? 
                                      match_time=Time.parse(match_info[1])
                                      datetime=match_time
                                      Rails.logger.info("#{tracking_info[30,tracking_info.length].nil?}")
                                      event=match_info[2]+(tracking_info[30,tracking_info.length].nil? ? "" : tracking_info[30,tracking_info.length])
                        else
                                      datetime=time 
                                      event= tracking_info
                        end
                        [datetime,event]
            end
            def max_in_status(status,shpmt_status)
                        if status=="initialized"||status=="in-process" || shpmt_status=="arrived"
                                    return shpmt_status
                        else
                                    status
                        end
            end
            def currency_abbr(currency)
                        {"CNY"=>"¥","EUR"=>"€", "GBP"=>"£","cny"=>"¥","eur"=>"€", "gbp"=>"£", "usd"=>"$", "USD"=>"$"}[currency]
            end
            def awb_type_desc(type,is_lkw)
                unless type == "fba"
                    {"postal"=>"邮政小包","t1"=>"航空货"}[type]
                else
                    {true=>"卡派",false=>"包裹"}[is_lkw]
                end
            end
            def check_awb_destination_and_type(awb)
                if awb.parcel_type == "fba"
                    parcel = Parcel.where(awb_no:awb.airwaybill_no).last
                    if parcel
                        if awb.is_lkw
                            return ["lck",parcel.fba_depot_code]
                        else
                            return ["fba",nil]
                        end
                    else
                        return [nil,nil]  
                    end
                elsif awb.parcel_type == "t1"
                    return ["t1",awb.destination]
                elsif awb.parcel_type == "postal"
                    return ["postal",nil]
                else
                    return [nil,nil]
                end
            end
            def gen_awb_clear_status(awb)
                if awb.awb_status["cts_self"] != true
                    {"Cleared"=>"全部清关","Inspection"=>"清关中"}[awb.awb_status["clr_status"]]||"未清关"
                else
                    "已自理"
                end
            end
            def check_arr_status(awb)
                if awb.awb_status["arr_status"].present?
                    return {"not-yet"=>"未转运","on-the-way"=>"转运中","arrived"=>"转运中"}[awb.awb_status['arr_status']]
                elsif awb.etd.present?
                    return awb.etd < Time.now ? "转运中" : "未转运"
                else
                    return "未转运"
                end
            end
            def get_truck_palte_by_awb(awb)
                if awb.parcel_type == "fba"&& awb.is_lkw == false
                    if awb.truck_plate.blank?
                        "ET Truck"
                    else
                         awb.truck_plate
                    end
                else
                    awb.truck_plate
                end
            end
  end
end