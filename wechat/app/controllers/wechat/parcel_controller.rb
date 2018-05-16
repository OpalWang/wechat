module Wechat
class ParcelController < ApplicationController
	protect_from_forgery
              skip_before_action :verify_authenticity_token, :only =>["set_quantity","calculate_price","commodity_create","add_commodity_nfzx","change_quantity","order_list"]
              before_action :auth_user,except: [:set_quantity]
              
  	def ygbs_new
                         logger.info("[#{session[:openid]}] into ygbs_new")
                         session[:shpmt_product]="阳光包税专线"
                         @wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                         order_info=WechatOrderInfo.where(wui_id:@wui.id).last
                         @info=order_info.present? ? order_info.info : nil
                         session[:order_id]=order_info.present? ? order_info.id : nil
                         logger.info("order_id: #{session[:order_id]}")
     		logger.info("ygbs_new rl_info:#{@info}")
                            if @info.present?&&@info.size>0
                                
	                         set_tax_fare_price
	              else
                           #删除所有已添加商品后，清空相关价格及包裹信息 
	              	clear_session_ygbs_half
                            end
                           
                            logger.info("ygbs_new session[:tax]:#{session[:tax]}")
                            logger.info("ygbs_new session[:fare]:#{session[:fare]}")
                            logger.info("ygbs_new session[:price]:#{session[:price]}")
                            logger.info("ygbs_new session[:web_fare]:#{session[:web_fare]}")
                           
                            if session[:sndr_id].present? &&(sndr=Wechat::ActiveAddress.find(session[:sndr_id])).present?
                              @sndr=sndr
                            else
                              @sndr=Wechat::ActiveAddress.where(parcel_owner: @wui.user_id,usage_type:"sender",country:"de").order('default_flag DESC,created_at DESC').first
                            end
                             if session[:rcpt_id].present?&&(rcpt=Wechat::ActiveAddress.find(session[:rcpt_id])).present?
                              @rcpt=rcpt
                            else
                              @rcpt=Wechat::ActiveAddress.where(parcel_owner: @wui.user_id,usage_type:"recipient",country:"cn").order('default_flag DESC,created_at DESC').first
                            end
  	end
               #阳光包税修改商品数量, 同时修改关税、申报总价值、包邮包税价格
               #sys_commodity_no,quantity
              def set_quantity
          		tax_zz_eur=0
          		declare_rmb_price_zz=0
                          woi=WechatOrderInfo.find(session[:order_id])
                          order_info=woi.info
                          order_info.each do |rl|
                                         if rl["sys_commodity_no"]==params["sys_commodity_no"]
                                                rl["quantity"]=params["quantity"]
                                         end
                                         #关税
                                           tax_zz_eur += BigDecimal.new(rl["tax_eur_price"].to_s)*BigDecimal.new(rl["quantity"].to_s)*BigDecimal.new("0.119")
                                          #申报总价值
                                          declare_rmb_price_zz +=BigDecimal.new(rl["declare_rmb_price"].to_s)*BigDecimal.new(rl["quantity"].to_s)
                                          
                            end
                            woi.update(info:order_info)
                            session[:tax] =  BigDecimal.new(sprintf("%.0f",tax_zz_eur))
                            session[:declare_rmb_price] =  BigDecimal.new(sprintf("%.0f",declare_rmb_price_zz))
                            fare=session[:fare].present? ? BigDecimal.new(session[:fare]) : 0
                            session[:price]=session[:tax]+fare
                            web_fare=session[:web_fare].present? ? BigDecimal.new(session[:web_fare]) : 0
                            session[:web_price]=session[:tax]+web_fare
                            render json: { status:'success', tax:session[:tax], declare_rmb_price: session[:declare_rmb_price],price: session[:price],web_price: session[:web_price] }.to_json
              end
              #阳光包税删除商品
              def delete_rl
                        logger.info("[#{session[:openid]}] into delete_rl")
              	tax_zz_eur=0
              	declare_rmb_price_zz=0
                         woi=WechatOrderInfo.find(session[:order_id])
                         order_info=woi.info
                         order_info.each do |rl|
                                           if rl["sys_commodity_no"]==params["sys_commodity_no"]
                                                         order_info.delete(rl)
                                           else
                                                        #关税
                                                        tax_zz_eur += BigDecimal.new(rl["tax_eur_price"].to_s)*BigDecimal.new(rl["quantity"].to_s)*BigDecimal.new("0.119")
                                                        #申报总价值
                                                        declare_rmb_price_zz +=BigDecimal.new(rl["declare_rmb_price"].to_s)*BigDecimal.new(rl["quantity"].to_s)
                                           end
                            end
                            woi.update(info:order_info)
                           session[:tax] =   BigDecimal.new(sprintf("%.0f",tax_zz_eur))
                           session[:declare_rmb_price] =  BigDecimal.new(sprintf("%.0f",declare_rmb_price_zz))
                            fare=session[:fare].present? ? BigDecimal.new(session[:fare]) : 0
                            session[:price]=session[:tax]+fare
                            web_fare=session[:web_fare].present? ? BigDecimal.new(session[:web_fare]) : 0
                            session[:web_price]=session[:tax]+web_fare
                            redirect_to parcel_ygbs_new_path
              end

              #阳光包税计算包裹价格(主要是运费!!!!)
              #url: /wechat/parcel/calculate_price
              #参数: length,width,height, weight, shpmt_product,sndr_origin_cntry
              def calculate_price
                            begin
                                           session[:weight]=params["weight"]
                                           session[:length]=params["length"]
                                           session[:width]=params["width"]
                                           session[:height]=params["height"]
                                           sum_weight=0
                                           woi=WechatOrderInfo.find(session[:order_id])
                                           if woi.present?
                                                   order_info=woi.info
                                                   if order_info.present?
                                           		order_info.each do |rl|
                                           			sum_weight += BigDecimal.new(rl["netweightPerUnit"].to_s)*BigDecimal.new(rl["quantity"].to_s)
                                           		end
                                           	end
                                           end
                                           raise"包裹重量不能小于商品总重量" if BigDecimal.new(params["weight"].to_s) < sum_weight
                                           total_length=BigDecimal.new(params["length"].to_s) + BigDecimal.new(params["width"].to_s) + BigDecimal.new(params["height"].to_s)
                                           wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                                           discount = 1
                                           volume_weight = BigDecimal.new(params["length"].to_s)*BigDecimal.new(params["width"].to_s)*BigDecimal.new(params["height"].to_s) / BigDecimal.new("6000")
                                           calc_weight = volume_weight > BigDecimal.new(params["weight"].to_s) ? volume_weight : BigDecimal.new(params["weight"].to_s)
                                           rank = wui.user_rank=="diamond" ? "diamond" : "no_diamond"
                                           fare= ParcelValuation.get_mypost4u_price(params["shpmt_product"],params["sndr_origin_cntry"],"cn",total_length,calc_weight, "general", discount, rank, channel="wechat")[0]
                                           Rails.logger.info("calculate_price fare===============:#{fare}")
                                           session[:fare]=fare
                                           web_fare= ParcelValuation.get_mypost4u_price(params["shpmt_product"],params["sndr_origin_cntry"],"cn",total_length,calc_weight, "general", discount, rank, channel="web")[0]
                                           Rails.logger.info("calculate_price web_fare===============:#{web_fare}")
                                           session[:web_fare]=web_fare
                                           tax = session[:tax].present? ? BigDecimal.new(session[:tax]) : 0
                                           Rails.logger.info("calculate_price tax=============:#{tax}")
                                           session[:price]=tax+fare
                                           session[:web_price]=tax+web_fare
                                           render json: { status:'success', price: session[:price],web_price: session[:web_price]}.to_json
                            rescue=>e
                                           logger.info("parcel_calculate_price errors: #{e.message}")
                                           render json: { status:'failure', reason:e.message}.to_json
                            end
              end
              #计算阳光包税的关税，申报总价值，总价格
              def set_tax_fare_price
                            tax_zz_eur=0
                            declare_rmb_price_zz=0
                            sum_weight=0
                            woi=WechatOrderInfo.find(session[:order_id])
                            order_info=woi.info
                            order_info.each do |rl|
                                           #关税
                                           tax_zz_eur += BigDecimal.new(rl["tax_eur_price"].to_s)*BigDecimal.new(rl["quantity"].to_s)*BigDecimal.new("0.119")
                                           #申报总价值
                                        	declare_rmb_price_zz +=BigDecimal.new(rl["declare_rmb_price"].to_s)*BigDecimal.new(rl["quantity"].to_s)
                               		
                            end
                            session[:tax] =  BigDecimal.new(sprintf("%.0f",tax_zz_eur))
                            session[:declare_rmb_price] =  BigDecimal.new(sprintf("%.0f",declare_rmb_price_zz))
                             Rails.logger.info("set_tax_fare_price: #{session[:fare]}")
                            fare=session[:fare].present? ? BigDecimal.new(session[:fare]) : 0
                            session[:price]=session[:tax]+fare
                            web_fare=session[:web_fare].present? ? BigDecimal.new(session[:web_fare]) : 0
                            session[:web_price]=session[:tax]+web_fare
              end

	def order_list
                         logger.info("[#{session[:openid]}] into order_list")
                         begin
                                      if params["rcpt_id"].blank?
                                            	raise "收件人不能为空！"
                                     	end
                                    	if params["sndr_id"].blank?
                                        	raise "寄件人不能为空！"
                                    	end
                                    	@importstatus = true
                                    	@import_msg = []
                                    	msg=[]
                                    	rcpt_params={}
                                    	rcpt=Wechat::ActiveAddress.find(params["rcpt_id"])
                                    	if rcpt.blank?
                                        	raise "收件人不存在"
                                    	end
                                    	rcpt_params[:country]=rcpt.country
                                	rcpt_params[:name]=rcpt.name
                                    	rcpt_params[:province]=rcpt.province
                                    	rcpt_params[:city]=rcpt.city
                                    	rcpt_params[:district]=rcpt.district
                                    	rcpt_params[:street]=rcpt.street
                                    	rcpt_params[:postcode]=rcpt.postcode
                                    	rcpt_params[:telephone]=rcpt.telephone
                                    	rcpt_params[:email]=rcpt.email
                                    	rcpt_params[:id_number]=rcpt.id_number
                                    	logger.info("111111111:#{rcpt_params}")
                                    	msg=CheckApiParams.mypost4u_check_recipient_address_params(rcpt_params)
		          
                                    	sndr_params={}
                                    	sndr=Wechat::ActiveAddress.find(params["sndr_id"])
                                    	if sndr.blank?
                                        	raise "寄件人不存在"
                                    	else
                                    	sndr_params[:country]=sndr.country
                                    	sndr_params[:name]=sndr.name
                                    	sndr_params[:city]=sndr.city
                                    	sndr_params[:street]=sndr.street
                                    	sndr_params[:postcode]=sndr.postcode
                                    	sndr_params[:telephone]=sndr.telephone
                                    	sndr_params[:email]=sndr.email
                                    	sndr_params[:house_num]=sndr.house_num
                                    	logger.info("2222222:#{sndr_params}")
                                    	msg=msg+CheckApiParams.mypost4u_check_sender_address_params(sndr_params)
                                              

                                    	if msg.blank?
                                            
                                                  session[:rcpt_id]=params["rcpt_id"]
                                                  session[:rcpt_name]=params["rcpt_name"]
                                                  session[:rcpt_tele]=params["rcpt_tele"]
                                                  session[:rcpt_address]=params["rcpt_address"]
                                                 
                                                  session[:sndr_id]=params["sndr_id"]
                                                  session[:sndr_name]=params["sndr_name"]
                                                  session[:sndr_tele]=params["sndr_tele"]
                                                  session[:sndr_address]=params["sndr_address"]
                                                   
                                    	else
                                                  @importstatus = false
                                                  @import_msg = msg
                                    	end
                                      end
                         rescue=>e
                             	@import_msg = [e.message] unless @import_msg.present?
                             	@importstatus = false
                             	Rails.logger.info("order list failure:#{e.message}")
                         ensure
                                     if !@importstatus
                                                	flash[:notice] = @import_msg
                                                	if session[:shpmt_product]=="阳光包税专线"
                                                    	redirect_to parcel_ygbs_new_path
                                                	elsif session[:shpmt_product]=="NFZX"
                                                    	redirect_to parcel_nfzx_new_path
                                                	end
                                     end
                        	end
	end

	def order_preview
                         logger.info("[#{session[:openid]}] into order_preview")
                         if session[:shpmt_product]=="阳光包税专线"
                            woi=WechatOrderInfo.find(session[:order_id])
                            order_info=woi.info
                            @info=order_info
                        else
                            @info=[]
                        end
	end

	def add_commodity
                         logger.info("[#{session[:openid]}] into ygbs add_commodity")
		@openid=session[:openid]
		@jsapi=Weixin.jsapi_ticket
		Rails.logger.info("add_commodity openid: [#{@openid}]/jsapi: [#{@jsapi}]")
		@appid=Weixin::APPID
                        
                         #历史添加过的商品
                         @history_barcodes=""
                         @wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                         woi=WechatOrderInfo.where(wui_id:@wui.id).last
                         if woi.present?
                                      if woi.info.present?
                                                    @history_barcodes= woi.info.map{|i|i["barcode"]}.join(";")
                                      end
                        end
                       

	end
	#初始化rl_info,declare_rmb_price,tax
	def commodity_create
	              begin
	                         logger.info("[#{session[:openid]}] into ygbs commodity_create")
                                      logger.info("commodity_create order_id:#{session[:order_id]}")
	                         @wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
	                         
                    	              if params["barcodes"].blank?
                    	                             raise "添加商品不能为空!"
                    	              end
                	              logger.info("params barcodes :#{params["barcodes"]}") #["8000050594209","8000050594803"]
                	             #处理添加的barcode
                                      #1.将字符串转化成数组，去掉空元素
                                      b_array= params["barcodes"].gsub("；",";").split(";")
                                      b_array.delete("")
                                      #2.去掉与历史barcode重复的元素,如果全部重复则返回添加页面(非扫码添加商品时不排除有重复元素)
                                      if session[:order_id].present?
                                                    woi=WechatOrderInfo.find(session[:order_id])
                                                    if (info=woi.info).present?
                                                                b_array=b_array-info.map{|info|info["barcode"]}
                                                                if b_array==[]
                                                                            raise "商品重复添加！"
                                                                end
                                                    end
                                      end
                                      logger.info("real add barcodes :#{b_array}")
                                        @status,@msg,@info=RegisterList.rlsByOverseasHost(@wui.email,b_array)
                                      if @status=="success"
                                                total_quantity=0  #商品种类计数
                                                if session[:order_id].blank?
                                                                woi=WechatOrderInfo.new
                                                                woi.wui_id=@wui.id
                                                                woi.email=@wui.email
                                                                woi.info=@info[0,15]
                                                                woi.save!
                                                                session[:order_id]=woi.id
                                                                total_quantity=@info.size
                                                                logger.info("commodity_create rl_info:#{woi.info}")
                                                else
                                                                woi=WechatOrderInfo.find(session[:order_id])
                                                                old_order_info=woi.info
                                                                if old_order_info.present?
                                                                            max_quantity=15-old_order_info.size
                                                                            logger.info("max_quantity:#{max_quantity}")
                                                                            new_order_info=old_order_info+@info[0,max_quantity]
                                                                            woi.update(info:new_order_info)
                                                                            total_quantity=old_order_info.size+@info.size
                                                                else
                                                                            logger.info("00000:#{@info[0,15]}")
                                                                            woi.update(info:@info[0,15])
                                                                            total_quantity=@info.size
                                                                end
                                                                logger.info("commodity_create rl_info:#{woi.info}")
                                                end
                	             		set_tax_fare_price
                                                                logger.info("商品种类:#{total_quantity}")
                                                                if total_quantity>15
                                                                    @msg="最多可添加15种商品，超出部分无效！"
                                                                end
                	                            redirect_to parcel_ygbs_new_path,:notice=>@msg
                	              else    
                	                            redirect_to parcel_add_commodity_path,:notice=>@msg
                	              end  
	              rescue=>e
	                            Rails.logger.info("commodity_create rescue: openid=#{session[:openid]}")
	                            logger.info("commodity_create errors: #{e.message}")
	                            flash[:notice]=e.message
	                            redirect_to parcel_add_commodity_path
	              end
	end

	def postal_create
                            Rails.logger.info("[#{session[:openid]}] into wechat postal_create")
                            userid=""
                            amount=""
                            related_num=[]
                            begin
                                           postal_params={}
                                           Rails.logger.info("#{params}")
                                           @status=true

                                           error=test_params(params)
                                           if error!=""
                                           	raise error
                                           end
                                           postal_params=params_transfer(params)
                                           logger.info("postal_params:#{postal_params}")
                                           @wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                                           user_name=@wui.email
                                           if @wui.email.include?("@")
		                        	         user_name=user_name.gsub("@","!")
		                              end
                                           pswd=Base64.encode64(user_name+@wui.user_id.to_s).chomp
                                           
                                           status,msg,parcel_num=WeixinUserInfo.create_parcel_overseas(postal_params,user_name,pswd)
                                           
                                           	if status=="success"
                                           		@msg="包裹【#{parcel_num}】创建成功，请到官网www.mypost4u.com继续支付"
                                       		#@msg="包裹【#{parcel_num}】创建成功"
                                       		if session[:shpmt_product]=="阳光包税专线"
		                                                        clear_session_ygbs
		                                      elsif session[:shpmt_product]=="NFZX"
		                                                        clear_session_nfzx
		                                      end
                                       	else
                                       		@msg=msg
                                       		@status=false
                                       	end
                                                   userid=@wui.user_id
                                                   amount=postal_params["informationOfParcel"][0]["totalPriceOfOrder"]
                                                   related_num=parcel_num.present? ? parcel_num.split : ""
                            rescue => e
                                          logger.info("wechat postal_create rescue: #{e.message}")
                                          @msg=e.message
                                          @status=false
                            ensure
                 #            	if session[:shpmt_product]=="阳光包税专线"
              			# 	redirect_to parcel_ygbs_new_path,:notice=>@msg
              			# elsif session[:shpmt_product]=="NFZX"
              			# 	redirect_to parcel_nfzx_new_path,:notice=>@msg
              			# end
              			if @status==true&&(Weixin::TEST_EMAIL.include?session[:openid])
              				session[:userid]=userid
              				session[:amount]=amount
              				session[:related_num] =related_num
              				redirect_to parcel_pay_path
              			else
              				if session[:shpmt_product]=="阳光包税专线"
          	    				redirect_to parcel_ygbs_new_path,:notice=>@msg
              	    			elsif session[:shpmt_product]=="NFZX"
              	    				redirect_to parcel_nfzx_new_path,:notice=>@msg
              	    			end
              			end
    		            end
  	end

              def nfzx_new
                          Rails.logger.info("[#{session[:openid]}] into nfzx_new")
                            session[:shpmt_product]="NFZX"
                            @info=session[:ml_info]
                            logger.info("nfzx_new session[:ml_info]:#{@info}")
                            @wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                            @rank=@wui.user_rank
                            if session[:sndr_id].present? &&(sndr=Wechat::ActiveAddress.find(session[:sndr_id])).present?
                              @sndr=sndr
                            else
                              @sndr=Wechat::ActiveAddress.where(parcel_owner: @wui.user_id,usage_type:"sender",country:"de").order('default_flag DESC,created_at DESC').first
                            end
                             if session[:rcpt_id].present?&&(rcpt=Wechat::ActiveAddress.find(session[:rcpt_id])).present?
                              @rcpt=rcpt
                            else
                              @rcpt=Wechat::ActiveAddress.where(parcel_owner: @wui.user_id,usage_type:"recipient",country:"cn").order('default_flag DESC,created_at DESC').first
                            end
              end

              def add_commodity_nfzx
                            begin
                                          logger.info("[#{session[:openid]}] into add_commodity_nfzx")
                                          @wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                                           if params["brand"]=="请选择品牌"||params["category"]=="请选择名称"
                                                         raise "请选择品牌及名称 ! "
                                           end
                                           @status,@msg,@info=MilkList.mlByOverseasHost(@wui.email,params["category"])
                                           if @status=="success"
                                                        #下单结束待清空
                                                        if session[:ml_info].blank?
                                                                        logger.info("blankblankblankblank")
                                                                        session[:ml_info]=Array.new
                                                                        
                                                                        session[:ml_info]<<@info
                                                        else
                                                                        if !session[:ml_info].map{|j|j["goodsCategory"]}.include?(@info["goodsCategory"])
                                                                                      
                                                                                      session[:ml_info]<<@info
                                                                        end
                                                         end
                                                         @error,@current_parcel_weight,@sumprice=get_weight(@wui.user_rank,"NFZX")
                                                         if @error==""
                                                         		session[:nfzx_weight]=@current_parcel_weight
                                                         		session[:nfzx_price]=@sumprice
                                                         		session[:tip]=""
                                                         	else
                                                         		session[:tip]=@error
                                                         end
                                                         redirect_to parcel_nfzx_new_path,:notice=>@msg
                                          else    
                                                redirect_to parcel_nfzx_new_path,:notice=>@msg
                                          end  
                            rescue=>e
                                          Rails.logger.info("add_commodity_nfzx rescue: openid=#{session[:openid]}")
                                          logger.info("add_commodity_nfzx errors: #{e.message}")
                                          flash[:notice]=e.message
                                          redirect_to parcel_nfzx_new_path,:notice=>@msg
                             end
              end
              #奶粉专线修改数量, 同时修改总重,价格
              def change_quantity
              		logger.info("into change_quantity")
              		session[:ml_info].each do |ml|
                                         	if ml["goodsCategory"]==params["goodsCategory"]
                                                	ml["quantity"]=params["quantity"]
                                         	end
                            end
                            @error,@current_parcel_weight,@sumprice=get_weight(params["rank"],"NFZX")
                            if @error==""
                             	session[:nfzx_weight]=@current_parcel_weight
                             	session[:nfzx_price]=@sumprice
                             	session[:tip]=""
                            else
                            		session[:tip]=@error
                            end
                            render json: { status:'success', msg: @error, weight: session[:nfzx_weight], price: session[:nfzx_price]}.to_json	
              end

              	#奶粉专线计算总重,价格
              def get_weight(rank,shpmt_product)
              	sumweight=0
    		sumprice=0
    		error=""
              	platinum_flag = false;
                         logger.info("sumweight:#{sumweight}")
                         session[:ml_info].each do |ml|
                            	if ml["goodsCategory"]=="ET-DE-086"||ml["goodsCategory"]=="ET-DE-087"||ml["goodsCategory"]=="ET-DE-088"||ml["goodsCategory"]=="ET-DE-089"||ml["goodsCategory"]=="ET-DE-090"||ml["goodsCategory"]=="ET-DE-091"||ml["goodsCategory"]=="ET-DE-092"
        			platinum_flag=true;
      		end
      		sumweight+=BigDecimal.new(sprintf("%.1f",BigDecimal.new(ml["netweightPerUnit"].to_s)*BigDecimal.new(ml["quantity"].to_s)))
      		end
      		if shpmt_product=="NFZX"
      			if rank=="ordinary"
			          	if sumweight<=4.8
			          		
			            		if platinum_flag==true
                                                                            current_parcel_weight=8
			              		#sumprice = 36.0
			           		else
                                                                            current_parcel_weight=7
			              		#sumprice = 30.50
			            		end
			           	elsif sumweight<=6.4 && sumweight>4.8
			           		
			            		if platinum_flag==true
                                                                            current_parcel_weight=10
			              		#sumprice = 45
			            		else
                                                                            current_parcel_weight=9
			              		#sumprice = 37.50
			            		end
			            	else
			            		error="已超出奶粉净重上线6.4KG"
			          	end
			else
			          	if sumweight<=4.8
			          		
			            		if platinum_flag==true
                                                                            current_parcel_weight=8
			              		#sumprice = 36.0
			            		else
                                                                            current_parcel_weight=7
			              		#sumprice = 30.50
			            		end
			          	elsif sumweight<=6.4 && sumweight>4.8
			          		
			            		if platinum_flag==true
                                                                            current_parcel_weight=10
			              		#sumprice = 45
			            		else
                                                                            current_parcel_weight=9
			              		#sumprice = 37.50
			            		end
			          	elsif sumweight<=8 && sumweight>6.4
			          		
			            		if platinum_flag==true
                                                                            current_parcel_weight=12
			              		#sumprice = 55
			            		else
                                                                            current_parcel_weight=11
			              		#sumprice = 46
			            		end
			          	elsif sumweight<=9.6 && sumweight>8
			          		
			            		if platinum_flag==true
                                                                            current_parcel_weight=14
			              		#sumprice = 64
			            		else
                                                                            current_parcel_weight=13
			              		#sumprice = 53
			            		end
			              elsif sumweight<=14.4 && sumweight>9.6
			              		
			              	if platinum_flag==true
                                                                            current_parcel_weight=18
			              		#sumprice = 91
			            		else
                                                                            current_parcel_weight=17
			              		#sumprice = 75
			            		end
			          	else
			            		error="已超出奶粉净重上线14.4KG"
			          	end
			end
		end
                         
                         total_length=BigDecimal.new("99") #默认长宽高33
                         wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                         discount = 1
                         rank = wui.user_rank=="diamond" ? "diamond" : "no_diamond"
                           
                         sumprice= ParcelValuation.get_mypost4u_price("奶粉专线","de","cn",total_length,current_parcel_weight, "general", discount, rank, channel="wechat")[0]
		logger.info("current_parcel_weight: #{current_parcel_weight}")
		logger.info("sumprice: #{sumprice}")
		return [error,current_parcel_weight,sumprice]
              end

              #奶粉专线删除商品
              def delete_ml
              		logger.info("[#{session[:openid]}] into delete_ml")
                            	session[:ml_info].each do |ml|
                                           if ml["goodsCategory"]==params["goodsCategory"]
                                                         session[:ml_info].delete(ml)
                                           end
                            end
                            @error,@current_parcel_weight,@sumprice=get_weight(params["rank"],"NFZX")
                            if @error==""
                                session[:nfzx_weight]=@current_parcel_weight
                                session[:nfzx_price]=@sumprice
                                session[:tip]=""
                            else
                                    session[:tip]=@error
                            end
                            redirect_to parcel_nfzx_new_path
              end

            def pay
                        logger.info("[#{session[:openid]}] into pay")
                        @parcel_num=session[:related_num][0]
                        @amount=session[:amount]
                        
            end

            def clear_session_ygbs_half
                        if session[:order_id].present?
                                    woi=WechatOrderInfo.find(session[:order_id])
                                    woi.update(info:nil)
                                    
                        end
                            session[:weight]=nil
                            session[:length]=nil
                            session[:width]=nil
                            session[:height]=nil

                            session[:tax]=nil
                            session[:declare_rmb_price]=nil
                            session[:fare]=nil
                            session[:price]=nil
                         session[:web_fare]=nil
                         session[:web_price]=nil
            end

	def clear_session_ygbs
                         if session[:order_id].present?
                                    woi=WechatOrderInfo.find(session[:order_id])
                                    woi.update(info:nil)
                                    
                        end
                        	session[:weight]=nil
                        	session[:length]=nil
                        	session[:width]=nil
                        	session[:height]=nil

                        	session[:tax]=nil
                        	session[:declare_rmb_price]=nil
                        	session[:fare]=nil
                        	session[:price]=nil
                         session[:web_fare]=nil
                         session[:web_price]=nil

                        	session[:rcpt_id]=nil
            		session[:rcpt_name]=nil
            		session[:rcpt_tele]=nil
            		session[:rcpt_address]=nil

            		session[:sndr_id]=nil
            		session[:sndr_name]=nil
            		session[:sndr_tele]=nil
            		session[:sndr_address]=nil
	end

              def clear_session_nfzx
                            session[:ml_info]=nil
                            session[:nfzx_weight]=nil
                            session[:nfzx_price]=nil

                            session[:rcpt_id]=nil
                            session[:rcpt_name]=nil
                            session[:rcpt_tele]=nil
                            session[:rcpt_address]=nil

                            session[:sndr_id]=nil
                            session[:sndr_name]=nil
                            session[:sndr_tele]=nil
                            session[:sndr_address]=nil
              end

              def test_params(params)
                         logger.info("[#{session[:openid]}] into test_params")
              	msg=""
              	if session[:shpmt_product]=="阳光包税专线"
                                    woi=WechatOrderInfo.find(session[:order_id])
                                    order_info=woi.info
                                      order_info.each do |rl|
	                            		if BigDecimal.new(rl["quantity"].to_s)<=0
	                            			msg<<"条形码【#{rl["barcode"]}】商品数量非法"
	                            		end
	                         end
	                         if BigDecimal.new(session[:price].to_s)<=0
	                         	            msg<<"包裹价格不能小于0"
	                         end
                     	elsif session[:shpmt_product]=="NFZX"
                     		session[:ml_info].each do |ml|
	                            		if BigDecimal.new(ml["quantity"].to_s)<=0
	                            			msg<<"条形码【#{ml["commodityBarcode"]}】商品数量非法"
	                            		end
	                         end
	                         if BigDecimal.new(session[:nfzx_price].to_s)<=0
	                         	            msg<<"包裹价格不能小于0"
	                         end

                     	end
                     	return msg
	                         	
              end

	def params_transfer(params)
                         logger.info("[#{session[:openid]}] into params_transfer: #{session[:shpmt_product]}")
		parcels_params = Hash.new
		parcels_params["shimpentProduct"] = session[:shpmt_product]
                            if session[:shpmt_product]=="阳光包税专线" #阳光包税
                                           parcels_params["length"] = session[:length]
                                           parcels_params["height"] = session[:height]
                                           parcels_params["width"] = session[:width]
                                           parcels_params["weight"] = session[:weight]
                            elsif session[:shpmt_product]== "NFZX" #奶粉专线
                                           parcels_params["length"] = 33
                                           parcels_params["height"] = 33
                                           parcels_params["width"] = 33
                                           parcels_params["weight"] = session[:nfzx_weight]
                            end
	
                            rcpt=Wechat::ActiveAddress.find(session[:rcpt_id])
                            sndr=Wechat::ActiveAddress.find(session[:sndr_id])
                            parcels_params['sender'] = {}
                            parcels_params['recipient'] = {}
                            parcels_params['sender']['country'] =sndr.country
                            parcels_params['sender']['name'] = sndr.name
                            parcels_params['sender']['city'] = sndr.city
                            parcels_params['sender']['street'] = sndr.street
                            parcels_params['sender']['houseNumber'] = sndr.house_num
                            parcels_params['sender']['postcode'] = sndr.postcode
                            parcels_params['sender']['telephone'] = sndr.telephone
                            parcels_params['sender']['email'] = sndr.email
                            parcels_params['recipient']['country'] = rcpt.country
                            parcels_params['recipient']['name'] = rcpt.name
                            parcels_params['recipient']['surname']=rcpt.surname||"."
                            parcels_params['recipient']['province'] = rcpt.province
                            parcels_params['recipient']['city'] = rcpt.city
                            parcels_params['recipient']['district'] = rcpt.district
                            parcels_params['recipient']['street'] = rcpt.street
                            parcels_params['recipient']['postcode'] = rcpt.postcode
                            parcels_params['recipient']['telephone'] = rcpt.telephone
                            parcels_params['recipient']['email'] = rcpt.email
                            parcels_params["recipient"]["idType"] = "id"
                            parcels_params["recipient"]["idNumber"] = rcpt.id_number
                            
                            info_parcels = Hash.new
                            info_parcels_for_form = Hash.new
                            parcels_params["informationOfParcel"] = []
                            info_parcels["informationOfGoods"] = []
                            info_parcels_for_form["informationOfGoods"] = []
                            if session[:shpmt_product] == "阳光包税专线" 
                                      woi=WechatOrderInfo.find(session[:order_id])
                                      order_info=woi.info
                                      logger.info("ygbs_new rl_info:#{order_info}")
                                     	info_parcels["informationOfGoods"] = order_info
                                      info_parcels_for_form["informationOfGoods"] = order_info
                                      info_parcels["totalPriceOfOrder"]=session[:price]
                            	info_parcels["taxOfOrder"]=session[:tax]
                             elsif session[:shpmt_product] == "NFZX" 
                                      info_parcels["informationOfGoods"] = session[:ml_info]
                                      info_parcels_for_form["informationOfGoods"] =session[:ml_info]
                                      info_parcels_for_form["goodsCode"] = params[:goodsCode]
                                      info_parcels["totalPriceOfOrder"]=session[:nfzx_price]
                            	info_parcels["taxOfOrder"]=0
                             end
                            
                            info_parcels["currency"]="EUR"
                            parcels_params["informationOfParcel"] << info_parcels
                      
                            parcels_params["serialNumber"]= ""
                            parcels_params["contractNumber"]= ""
                            parcels_params["returnCarrier"]="" 
                            parcels_params["returnNumber"]=""
                            parcels_params["notificationUri"]=""
                            parcels_params["notifiedFiles"]=""
                            parcels_params["syncflag"]=true
                            return parcels_params
              end

	protected
	def auth_user
	    	#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
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