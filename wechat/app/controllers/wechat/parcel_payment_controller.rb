module Wechat
class ParcelPaymentController < ApplicationController
	IMG_DIR="app/assets/images/wechat/pay/"
    	SCREENSHOT_SCRIPT="lib/tasks/wechatpay_screenshot.js"
	#待开发币种选择，欧元必填发票信息====
	#默认微信人民币

	def new
		begin
			#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
			@wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
			@wechatpay = "Y" 
			@credit_use = "N"
			if params["parcel_num"].present?
				session[:related_num]=params["parcel_num"].split
			end
			session[:userid]=@wui.user_id
			session[:description] = "包裹寄送费用(微信)"
	                         session[:allow_currency] = ["EUR","CNY"]
	                         session[:allow_payment] = ["credit","wechatpay"]
	                         session[:pmnt_type] = "parcel"
	                         session[:order_type] = "parcel"
	                         session[:origin_currency]="EUR"
			#调用接口重新获取parcel======
			status,msg,info=WeixinUserInfo.getUnpaidParcelsByOverseasHost(session[:userid],session[:related_num])
	             	
			if status=="success"
				session[:amount]=info["amount"]
				session[:currency] =info["currency"]
				session[:cur2rmb_rate] = info["cur2rmb_rate"]
				session[:amount_cny] =  info["amount_cny"]
				session[:amount_eur] = session[:amount]
				session[:country] = info["country"]

				#默认支付人民币
				# session[:amount]=session[:amount_cny] 
				# session[:currency] ="CNY"
				if session[:allow_payment].include? "credit"
				         	@current_credit = @wui.obtain_score

					if @current_credit!=@wui.user_credit
						@wui.user_credit=@current_credit
						@wui.save
					end
				        	@credit_use = "Y" if @current_credit >= User.new.money_to_score(
					          	BigDecimal.new(session[:amount].to_s),
					          		session[:currency],
					          		session[:origin_currency]
				         	)
				end
			else
				raise "getUnpaidParcelsByOverseasHost error: #{msg}"
			end

		rescue => e
			logger.info("payment new rescue:#{e.message}")
			flash[:notice]=e.message
		end
	end

	def create
		logger.info("session[:userid]:#{session[:userid]}")
		if params[:checkout_way].blank? || params[:checkout_way].size == 0
		        flash[:notice] = "请选择一种支付方式进行支付"
		        redirect_back(fallback_location: root_path) and return
		end
		checkout_way = params[:checkout_way][0]
		if checkout_way=="wechatpay"&& (params[:consumer_name].blank? || params[:consumer_phone].blank? || params[:consumer_id].blank?  )
		        flash[:notice] = "微信支付，请填写支付人信息"
		        redirect_back(fallback_location: root_path) and return
		end
		redirect_path = weixin_parcel_list_path
		#调用接口支付
		
		begin
			status,msg,info=WeixinUserInfo.wechat_pay_overseas(checkout_way,params[:userid],params[:amount],params[:related_num],params[:currency],params[:cur2rmb_rate],params[:amount_cny],params[:amount_eur],params[:description],params[:country],params[:allow_currency],params[:allow_payment],params[:origin_currency],params[:pmnt_type],params[:order_type],params[:consumer_name],params[:consumer_phone],params[:consumer_id])
			
			if checkout_way=="credit"
				if status=="success"
					flash[:notice]="恭喜您，您的包裹支付成功。"
					session_clear
				else
					flash[:notice] = "请求支付失败，请您联系客服或者稍后再试"
				end
			elsif checkout_way=="wechatpay"
				if status=="success"
					logger.info("!!!!qianhai_info:#{info}")
					session_clear
					redirect_path=parcel_payment_oceanpay_redirect_path(trade_no: info["trade_no"])
				else
					flash[:notice] = "请求支付失败，请您联系客服或者稍后再试"
				end
			end
			
		rescue=>e
			Rails.logger.info("payment_create failure:#{e.message}")
			Rails.logger.info("#{e.backtrace}")
			flash[:notice] = "请求支付失败，请您联系客服或者稍后再试"
		ensure
			
      			redirect_to  redirect_path
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
	end

	def oceanpay_redirect
		logger.info("into oceanpay_redirect ==== [#{Time.now}]")
		@trade_no=params["trade_no"]
		
		@name = "#{@trade_no.to_s}.png"
    		#http://world-paket.de:5000/parcel_payments/oceanpay_redirect?trade_no=mypost4u_TM180323001110072005
		url=Settings.wechat.wechatpay_screenshot_url+@trade_no+"&redflag"
		logger.info("11111111111url:#{url}")
		Dir.mkdir IMG_DIR unless Dir.exist? IMG_DIR
		logger.info("222222")
		img_path=IMG_DIR+@name.to_s
		if !File.exists?(img_path) 
			begin
				logger.info("3333")
		                        	timeout = UtilsFunction::TIMEOUT_NORMAL*3
		                        	Timeout::timeout(timeout){
		                            logger.info("WECHATPAY SCREENSHOT START [ timeout #{timeout} phantomjs #{url} ")
		                            system "phantomjs #{SCREENSHOT_SCRIPT} '#{url}' '#{img_path}' "
		                            logger.info("WECHATPAY SCREENSHOT END!!!")
		                        }
	                    	rescue =>e
		                        logger.info("SCREENSHOT FAILURE: [#{e.message}]")
		                       
		            end
		end
		@img_path=img_path
		logger.info("22222222222:#{@img_path}")
	end
end
end