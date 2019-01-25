module Wechat
class ParcelPaymentController < ApplicationController
	layout "layouts/wechat/application"
	protect_from_forgery
	skip_before_action :verify_authenticity_token, :only =>["credit_pay","pre_wxpay","wxpay_redirect","coupon_exchange","coupon_restore","cancel"]
	#before_action :auth_user,except: [:wxpay_redirect]
	# IMG_DIR="app/assets/images/wechat/pay/"
 	#SCREENSHOT_SCRIPT="lib/tasks/wechatpay_screenshot.js"

	def new
		begin
			@status=true
			@appid=Settings.wechat.openid 
			@openid=session[:openid]
			@wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
			@wechatpay = "Y" 
			@credit_use = "N"
			session[:pay_type]=params["type"].present? ? params["type"] : "parcel_pay"
			Rails.logger.info("pay_type:#{session[:pay_type]}")
			redirect_path = {"parcel_pay"=>parcel_wait_pay_path,"extra_pay"=>parcel_extra_pay_path,"milkvip"=>milkvip_apply_platinum_path,"returning_parcel_pay"=>returning_parcel_index_path}[session[:pay_type]]
			if @wui.blank?
				raise "网络出错，请重试！"
			end
			if session[:pay_type]=="extra_pay"
				session[:related_num]=params['extra_pay_id']
				if session[:related_num].blank?
					raise "请选择需要进行付款的包裹"
				end
				session[:userid]=@wui.user_id
				session[:description] = "包裹补款费用(微信)"
		                         session[:allow_currency] = ["CNY"]
		                         session[:allow_payment] = ["credit","wechatpay"]
		                         session[:pmnt_type] = "extra-money-of-parcel"
		                         session[:order_type] = "parcel"
		                         session[:origin_currency]="EUR"
		                         #调用接口重新获取支付信息======
		                         status,msg,info=WeixinUserInfo.getUnpaidParcelsByOverseasHost(session[:userid],session[:related_num],session[:pay_type])
		            elsif session[:pay_type]=="milkvip"
		            		session[:userid]=@wui.user_id
				session[:description] = "白金会员开通费用(微信)"
		                         session[:allow_currency] = ["CNY"]
		                         session[:allow_payment] = ["credit","wechatpay"]
		                         session[:pmnt_type] = "milkvip"
		                         session[:order_type] = "parcel"
		                         session[:origin_currency]="EUR"
		                         status,msg,info=WeixinUserInfo.getMilkvipByOverseasHost(session[:userid])
		            elsif session[:pay_type]=="returning_parcel_pay"
		            		if params['rp_num'].blank?
		            			raise "请选择需要进行付款的包裹"
		            		else
		            			if params['rp_num'].class.to_s=="Array"
		            				session[:related_num]=params['rp_num']
		            			else
		            				session[:related_num]=[params['rp_num']]
		            			end
		            			session[:userid]=@wui.user_id
					session[:description] = "购买Retour费用(微信)"
			                         session[:allow_currency] = ["CNY"]
			                         session[:allow_payment] = ["credit","wechatpay"]
			                         session[:pmnt_type] = "returning-parcel"
			                         session[:order_type] = "parcel"
			                         session[:origin_currency]="EUR"
		            		end
		            		status,msg,info=WeixinUserInfo.getUnpaidParcelsByOverseasHost(session[:userid],session[:related_num],session[:pay_type])
		            else
		            		#显示折扣券
				@vouchers=Coupon.where(coupon_type:"voucher",owner: @wui.user_id,status:"unused")

		            		if params["parcel_num"].present?
		            			if params["parcel_num"].class.to_s=="Array"
		            				session[:related_num]=params["parcel_num"]
		            			else
						session[:related_num]=[params["parcel_num"]]
					end
				end
				if session[:related_num].blank?
					raise "请选择需要进行付款的包裹"
				end
				Rails.logger.info("related_num original:#{session[:related_num]}")
		             		session[:userid]=@wui.user_id
				session[:description] = "包裹寄送费用(微信)"
		                         session[:allow_currency] = ["CNY"] 
		                         session[:allow_payment] = ["credit","wechatpay"]
		                         session[:pmnt_type] = "parcel"
		                         session[:order_type] = "parcel"
		                         session[:origin_currency]="EUR"
		                         #调用接口重新获取支付信息======
		                         status,msg,info=WeixinUserInfo.getUnpaidParcelsByOverseasHost(session[:userid],session[:related_num],session[:pay_type])
			end
			
			if status=="success"
				session[:amount]=info["amount"]
				session[:currency] =info["currency"]
				session[:cur2rmb_rate] = info["cur2rmb_rate"]
				session[:amount_cny] =  info["amount_cny"]
				session[:amount_eur] = session[:amount]
				session[:country] = info["country"]
				session[:origin_currency]=info["origin_currency"]
				session[:related_num]=info["related_num"]
				session[:origin_amount]=info["amount"]

				if session[:allow_payment].include? "credit"
				         	@current_credit = @wui.obtain_score

					if @current_credit!=@wui.user_credit
						@wui.user_credit=@current_credit
						@wui.save
					end
					@needed_credit=User.new.money_to_score(
					          	BigDecimal.new(session[:amount].to_s),
					          		session[:currency],
					          		session[:origin_currency]
				         	)
				        	@credit_use = "Y" if @current_credit >= @needed_credit&&session[:allow_payment].include?("credit")
				end
				@wechatpay="N" if BigDecimal.new(session[:amount_cny].to_s)<=0 
			else
				@status=false
				raise msg
			end
			
		rescue => e
			logger.info("payment new rescue:#{e.message}")
			flash[:notice]=e.message
			@status=false
		ensure
			if @status==false
				redirect_to redirect_path,:notice=>@msg
			else
				render :new
			end 
		end

	end
	#换算折扣后对应的欧元价格，人民币价格(包裹支付保留整数位，补款保留2位小数)，积分
	def coupon_exchange
		begin
			wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
			if wui.blank?
				raise "网络出错，请重试！"
			end
			c=Coupon.find_by(id:params["c_id"],owner:wui.user_id,status:"unused")
			if c.present?
				amount_eur=BigDecimal.new(params["total_amount_eur"].to_s)-BigDecimal.new(c.amount.to_s)
				if amount_eur<=0
					amount_eur=0
				end
				amount_cny=BigDecimal.new(sprintf("%.0f", amount_eur*BigDecimal.new(params["cur2rmb_rate"])))
				credit=User.new.money_to_score(amount_eur,"EUR","EUR")
				session[:amount]=amount_eur
				session[:amount_eur]=amount_eur
				session[:amount_cny]=amount_cny
				logger.info("credit:#{credit}")
				render json: { status:'success',  amount_eur: amount_eur,amount_cny:amount_cny,credit:credit,c_id:c.id,c_amount:c.amount}.to_json
			else
				raise "Coupon id=[#{params["c_id"]}] owner=[#{wui.user_id}] not exist"
			end
		rescue => e
			logger.info("coupon_exchange rescue:#{e.message}")
			render json: { status:'failure',  reason:e.message}.to_json
		end
	end
	#取消折扣券回复原价
	def coupon_restore
		begin
			wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
			if wui.blank?
				raise "网络出错，请重试！"
			end
			
			amount_eur=BigDecimal.new(params["total_amount_eur"].to_s)
			if amount_eur<=0
				amount_eur=0
			end
			amount_cny=BigDecimal.new(sprintf("%.0f", amount_eur*BigDecimal.new(params["cur2rmb_rate"])))
			credit=User.new.money_to_score(amount_eur,"EUR","EUR")
			session[:amount]=amount_eur
			session[:amount_eur]=amount_eur
			session[:amount_cny]=amount_cny
			logger.info("credit:#{credit}")
			render json: { status:'success',  amount_eur: amount_eur,amount_cny:amount_cny,credit:credit}.to_json
			
		rescue => e
			logger.info("coupon_restore rescue:#{e.message}")
			render json: { status:'failure',  reason:e.message}.to_json
		end
	end

	def credit_pay
		logger.info("session[:userid]:#{session[:userid]}")
		@status=true
		checkout_way = params[:checkout_way][0]
		if session[:pay_type].present?
			redirect_path = {"parcel_pay"=>weixin_parcel_list_path,"extra_pay"=>parcel_extra_pay_path,"milkvip"=>parcel_ygbs_new_path,"returning_parcel_pay"=>returning_parcel_index_path}[session[:pay_type]]
		else	
			redirect_path = weixin_parcel_list_path
		end
		begin
			if params["coupon_id"].present?
				coupon_id=[params["coupon_id"]]
			else
				coupon_id=nil
			end
			status,msg,info=WeixinUserInfo.wechat_pay_overseas(checkout_way,params[:userid],params[:amount],session[:related_num],params[:currency],params[:cur2rmb_rate],params[:amount_cny],params[:amount_eur],params[:description],params[:country],params[:allow_currency],params[:allow_payment],params[:origin_currency],params[:pmnt_type],params[:order_type],coupon_id,params[:coupon_amount])
			Rails.logger.info("related_num:#{params[:related_num]}")
			if checkout_way=="credit"
				if status=="success"
					if session[:pay_type]=="milkvip"
						flash[:notice]="恭喜您成功开通杂货包税线路, 请继续下单！"
					else
						flash[:notice]="支付成功！"
					end
					session_clear
				else
					flash[:notice] = "请求支付失败，请您联系客服或者稍后再试。{#{msg}}"
				end
			end
			
		rescue=>e
			Rails.logger.info("credit_pay failure:#{e.message}")
			Rails.logger.info("#{e.backtrace}")
			@status=false
			flash[:notice] = "请求支付失败，请您联系客服或者稍后再试"
		ensure
      			redirect_to  redirect_path
		end
		
	end
	#微信支付前处理
	def pre_wxpay
		Rails.logger.info("into pre_wxpay")
		Rails.logger.info("coupon_id:#{params["coupon_id"]}")
		Rails.logger.info("related_num:#{session[:related_num]}")
		if params["coupon_id"].present?
			coupon_id=[params["coupon_id"]]
		else
			coupon_id=nil
		end
		#1.产生系统支付单号
		checkout_way = "wechatpay2"
		status,msg,info=WeixinUserInfo.wechat_pay_overseas(checkout_way,params[:userid],params[:amount],session[:related_num],params[:currency],params[:cur2rmb_rate],params[:amount_cny],params[:amount_eur],params[:description],params[:country],params[:allow_currency],params[:allow_payment],params[:origin_currency],params[:pmnt_type],params[:order_type],coupon_id,params[:coupon_amount])
		if status=="success"
			logger.info("!!!!mp4system_info:#{info}")
			#2.微信统一下单接口产生预支付交易单: prepay_id
			#########
			ip=request.remote_ip
			Rails.logger.info("ip :#{ip}")
			resp=Wxpay.pre_pay(info["trade_no"],session[:openid],(BigDecimal.new(session[:amount_cny].to_s)*100).to_i,ip)
			
			if resp["status"]=="succ"
				prepay_id=resp["info"]["prepay_id"]
				WxpayInfo.create!({
					prepay_id: prepay_id,
					owner: params[:userid],
					tax_num: info["trade_no"],
					amount: params[:amount_cny],
					currency: "CNY",
					related_num: [params[:related_num]],
					expired_time: Time.now+1.hour,
					country: params[:country],
					coupon_id:coupon_id
				})
			else
				render json: { status:'fail', msg: "prepay_id产生失败:#{resp["info"]["err_msg"]}"}.to_json and return
			end
			##########
			session_clear
			render json: { status:'success', prepay_id: prepay_id}.to_json and return
		else
			render json: { status:'fail', msg: "请求支付失败，请您联系客服或者稍后再试。"}.to_json and return
		end	
	end

	def session_clear
		 session[:userid] = nil
		      session[:amount] = nil
		      session[:currency] = nil
		      session[:description] = nil
		      session[:country] = nil
		      session[:allow_currency] = nil
		      session[:allow_payment] = nil
		      session[:related_num] = nil
		      session[:origin_currency] = nil
		      session[:pmnt_type] = nil
		      session[:cur2rmb_rate] = nil
		      session[:amount_cny] = nil
		      session[:inv_country]= nil
		      session[:name]= nil
		      session[:city]= nil
		      session[:street]= nil
		      session[:postcode]= nil
		      session[:company_tax_no]= nil
		      session[:company_name]= nil
		      session[:amount_eur] = nil
		      session[:order_type] = nil
		      session[:pay_type]=nil
	end

	def cancel
		Rails.logger.info("#cancel related_num:#{session[:related_num]}")
		Rails.logger.info("#cancel pay_type:#{session[:pay_type]}")
		prepay_id=params[:prepay_id]
		WxpayInfo.find_by(prepay_id:prepay_id).update(status: "canceled")
		render json: { status:'success'}.to_json and return
	end
	#phantomjs失败
	def oceanpay_redirect
		logger.info("into oceanpay_redirect ==== [#{Time.now}]")
		@wi=WxpayInfo.where(prepay_id:params["prepay_id"],status:"unpaid").where("expired_time>?",Time.now).last
		
		# @name = "#{@trade_no.to_s}.png"
  #   		#http://world-paket.de:5000/parcel_payments/oceanpay_redirect?trade_no=mypost4u_TM180323001110072005
		# url=Settings.wechat.wechatpay_screenshot_url+@trade_no+"&redflag"
		# logger.info("11111111111url:#{url}")
		# Dir.mkdir IMG_DIR unless Dir.exist? IMG_DIR
		# logger.info("222222")
		# img_path=IMG_DIR+@name.to_s
		# if !File.exists?(img_path) 
		# 	begin
		# 		logger.info("3333")
		#                         	timeout = UtilsFunction::TIMEOUT_NORMAL*3
		#                         	Timeout::timeout(timeout){
		#                             logger.info("WECHATPAY SCREENSHOT START [ timeout #{timeout} phantomjs #{url} ")
		#                             system "phantomjs #{SCREENSHOT_SCRIPT} '#{url}' '#{img_path}' "
		#                             logger.info("WECHATPAY SCREENSHOT END!!!")
		#                         }
	 #                    	rescue =>e
		#                         logger.info("SCREENSHOT FAILURE: [#{e.message}]")
		                       
		#             end
		# end
		# @img_path=img_path
		# logger.info("22222222222:#{@img_path}")
	end
	
	#微信支付异步通知
	def wxpay_redirect
		Rails.logger.info("into wxpay_redirect")
		begin
			request.body.rewind
			if (body=request.body.read).present?

				logger.info("body: [#{body}]")

				doc = Nokogiri::Slop body

				xbuilder = Builder::XmlMarkup.new(:target => ret_xml="")
				if doc.xml.return_code.content =="SUCCESS"
		      			#1.校验签名
		      			if check_sign(doc)==true
			      			out_trade_no=doc.xml.out_trade_no.content
			      			WxpayInfo.transaction do
				      			wi=WxpayInfo.lock.where(tax_num:out_trade_no).last
				      			if wi.present?
				      				#2.校验返回的订单金额是否与商户侧的订单金额一致
				      				if wi.amount*100==(doc.xml.total_fee.content).to_i
				      					wi.transaction_id=doc.xml.transaction_id.content#微信支付订单号
				      					wi.pay_time=Time.parse(doc.xml.time_end.content) if doc.xml.time_end.present?
				      					wi.pay_detail=pay_detail_transfer(doc)
				      					wi.status="paid"
				      					wi.save!
				      					xbuilder.xml{
							            			xbuilder.return_code "SUCCESS"
							            		}
							            		#折扣券处理逻辑
							            		if wi.coupon_id.present?
							            			Coupon.where(id: wi.coupon_id,owner:wi.owner).update_all(status:"used")
							            		end
							            		# status,msg=wi.after_paid_oversea
							            		# Rails.logger.info("WxpayInfo[#{wi.id}] after_paid_oversea status:#{status}")
						      			Thread.new do
										begin
											cq=CallbackQueue.create!(
												  callback_interface: "wxpay_deal_request",
												  reference_id: wi.tax_num,
												  status: "init",
												  try_amount: 5,
												  tried_amount: 0
											 )
											#status=parcel_payment.handle_sucessful_paid
											status,msg=wi.after_paid_oversea
												
											if status=="success"
												cq.delete
											else
												raise msg
											end
										rescue=>e
											Rails.logger.info("WxpayInfo after_paid_oversea rescue:#{msg}")
										end
									end
				      				else
				      				 	Rails.logger.info("wxpay_redirect: Inconsistency of amount!!! ")
				      					xbuilder.xml{
							            			xbuilder.return_code "FAIL"
							       			xbuilder.return_msg "Inconsistency of amount"
							            		}
				      				end
				      			 else
				      			 	Rails.logger.info("WxpayInfo not found")
					      			xbuilder.xml{
						            			xbuilder.return_code "SUCCESS"
						            		}
					      		end
					      	end
			      			
			      		else
			      		 	Rails.logger.info("Sign Check Wrong")
			      			xbuilder.xml{
				            			xbuilder.return_code "FAIL"
				            			xbuilder.return_msg "签名失败"
				            		}
			      		end
		      			
		      		end

				logger.info("ret [#{ret_xml}]")
				render plain: ret_xml and return
			end

		rescue=> e
			Rails.logger.info("wxpay_redirect rescue: #{e.message}")
		end
	end
	#校验支付结果签名
	def check_sign(doc)
		Rails.logger.info("into check_sign")
		origin_sign=doc.xml.sign.content
		pay=Wxpay.new
		pay.return_code=doc.xml.return_code.content
		pay.appid=doc.xml.appid.content
		pay.mch_id=doc.xml.mch_id.content
		#pay.device_info=doc.xml.device_info.content 
		pay.nonce_str=doc.xml.nonce_str.content
		#pay.sign_type=doc.xml.sign_type.content 
		pay.result_code=doc.xml.result_code.content
		#pay.err_code=doc.xml.err_code.content
		#pay.err_code_des=doc.xml.err_code_des.content
		pay.openid=doc.xml.openid.content
		pay.is_subscribe=doc.xml.is_subscribe.content 
		pay.trade_type=doc.xml.trade_type.content
		pay.bank_type=doc.xml.bank_type.content
		pay.total_fee=doc.xml.total_fee.content
		#pay.settlement_total_fee=doc.xml.settlement_total_fee.content 
		pay.fee_type=doc.xml.fee_type.content 
		pay.cash_fee=doc.xml.cash_fee.content
		if doc.xml.cash_fee.content!=doc.xml.total_fee.content
		#pay.cash_fee_type=doc.xml.cash_fee_type.content 
		pay.coupon_fee=doc.xml.coupon_fee.content
		pay.coupon_count=doc.xml.coupon_count.content 
		pay.coupon_fee_0=doc.xml.coupon_fee_0.content
		pay.coupon_id_0=doc.xml.coupon_id_0.content
		end
		pay.transaction_id=doc.xml.transaction_id.content
		pay.out_trade_no=doc.xml.out_trade_no.content
		#pay.attach=doc.xml.attach.content 
		pay.time_end=doc.xml.time_end.content

		calued_sign=pay.gen_sign
		if origin_sign==calued_sign
			return true 
		else
			return false 
		end
	end

	def pay_detail_transfer(doc)
		hash=Hash.new
		hash["openid"]=doc.xml.openid.content
		hash["bank_type"]=doc.xml.bank_type.content
		hash["total_fee"]=doc.xml.total_fee.content
		#hash["settlement_total_fee"]=doc.xml.settlement_total_fee.content#应结订单金额=订单金额-非充值代金券金额，应结订单金额<=订单金额
		hash["fee_type"]=doc.xml.fee_type.content
		hash["cash_fee"]=doc.xml.cash_fee.content
		#hash["cash_fee_type"]=doc.xml.cash_fee_type.content
		#hash["coupon_count"]=doc.xml.coupon_count.content
		hash["time_end"]=doc.xml.time_end.content
		hash
	end

	protected
	def auth_user
	    	#session[:openid]="oJAlcw83X9NPAAwshp3oeHvZFZF4"
             	session[:server]="overseas"
	    	begin
	      		if session[:openid]==nil
	        
	        			code=params[:code]
	        			if code.present?
	          				oauth2_at,openid=Weixin.get_oauth2_access_token(code)
	          				logger.info("oauth2_at,openid: [#{oauth2_at}],[#{openid}]")
	          				if oauth2_at!=""&&openid!=""
	            					session[:openid]=openid
	          				else
	            					raise "get openid failure"
	          				end
	        			else
	          				raise "no code error !"
	        			end
	      		end
	      		wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
	      		if wui.blank?
	        			redirect_to weixin_home_path
	      		end
	    	rescue=>e
	      		logger.info("auth_user errors: #{e.message}")
	      		redirect_to weixin_home_path
	    	end
	end

end
end
