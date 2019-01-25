module Wechat
class WeixinController < ApplicationController
	#skip_before_action :verify_authenticity_token
	layout "layouts/wechat/application"
	def auth
		logger.info("into auth")
		logger.info("echostr: #{params[:echostr]}")
		return render plain: params[:echostr]
	end
	#1. 接收到MsgType，Event，EventKey, 回复 "请输入包裹号或者国际运单号"
	#2. 根据包裹号或者国际运单号返回最新物流信息
	#3. 用户绑定跳转页面
	
	def menu
		logger.info("into menu")
		request.body.rewind
		body=request.body.read

		logger.info("body: [#{body}]")

		doc = Nokogiri::Slop body
		to_username=doc.xml.ToUserName.content
		from_username=doc.xml.FromUserName.content
		msg_type=doc.xml.MsgType.content


		xbuilder = Builder::XmlMarkup.new(:target => ret_xml="")
		if msg_type=="event"
			event=doc.xml.Event.content
			 if event=="subscribe"
			 	 logger.info("into subscribe")
			# 	 title="欢迎关注 Europe Time Express！"
			# 	 descp="我们致力于为您提供最快的物流，最好的服务。请点击查看使用指南。"
			# 	 picUrl="http://mmbiz.qpic.cn/mmbiz_jpg/xg5dgG6ib5HvUNPjzppqJoI96RndVq0I5IeicoSNsfxbDkuZia6fVhT0mkKiaTxdw0DXbe7EScW67icdib2GM2icibAWWg/0?wx_fmt=jpeg"
			# 	 url="http://mp.weixin.qq.com/s?__biz=MzI2MDU2OTA4Mw==&mid=100000021&idx=1&sn=18c162416105dd533446642749135925&chksm=6a66e3815d116a97fcada4095297aa47c967019c0fc6afeefb15c3ffc7d4f185dab4b54fa125"
			# 	 xbuilder.xml{
			# 		xbuilder.ToUserName{
			# 			xbuilder.cdata! from_username
			# 		}
			# 		xbuilder.FromUserName{
			# 			xbuilder.cdata! to_username
			# 		}
			# 		xbuilder.CreateTime Time.now.to_i
			# 		xbuilder.MsgType {
			# 			xbuilder.cdata! "news"
			# 		}
			# 		xbuilder.ArticleCount 1
			# 		xbuilder.Articles {
			# 			xbuilder.item {
			# 				xbuilder.Title{
			# 					xbuilder.cdata! title
			# 				}
			# 				 xbuilder.Description{
			# 					xbuilder.cdata! descp
			# 				}
			# 				xbuilder.PicUrl{
			# 					xbuilder.cdata! picUrl
			# 				}
			# 				xbuilder.Url{
			# 					xbuilder.cdata! url
			# 				}
			# 			}
			# 		}
					xbuilder.xml{
						xbuilder.ToUserName{
							xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
							xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
							xbuilder.cdata! "text"
						}
						xbuilder.Content {
							xbuilder.cdata! "欢迎关注 Europe Time Express！\n请点击“个人中心”-“帐号绑定”，完成操作后即可共享官网帐号的积分优惠！\n参加”我的TIME”-”分享有礼”活动，即可获得无门槛3欧元代金券，下单立减！"
						}
					}
					#默认以微信号登录，打标签mypost4u
					session[:openid]=params["openid"]
					Thread.new do
			                                     	status,msg=WeixinUserInfo.subscribe(params["openid"])
						if status==false
			                                     		Rails.logger.info("subscribe_wx_user fail: #{msg}")
			                                      	CallbackQueue.create!(
			                                                  callback_interface: "wx_subscribe_request",
			                                                  reference_id: params["openid"],
			                                                  status: "init",
			                                                  try_amount: 5,
			                                                  tried_amount: 0
			                                             )
			                                      end
			                         end
			elsif event=="unsubscribe"
				logger.info("into unsubscribe")
				release_user(from_username)
				xbuilder.xml{
					xbuilder.ToUserName{
						xbuilder.cdata! to_username
					}
					xbuilder.FromUserName{
						xbuilder.cdata! from_username
					}
				}
			elsif event=="CLICK"
				event_key=doc.xml.EventKey.content
				logger.info("event_key: #{event_key}")
				if event_key=="trickinginfo"
					xbuilder.xml{
						xbuilder.ToUserName{
							xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
							xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
							xbuilder.cdata! "text"
						}
						xbuilder.Content {
							xbuilder.cdata! "请输入国际物流号或者包裹编号前14位"
						}
					}
				elsif event_key=="credit_gift"
					logger.info("into sharing")
					title=" 新用户大福利，千万不要错过！"
					descp="凡绑定Mypost4u帐号的新用户，成功将原文分享至朋友圈，我们将为您奉上200积分的奖励 (约可抵扣3欧元现金)！抓紧时间行动吧 ! \n戳↓↓"
					picUrl="http://mmbiz.qpic.cn/mmbiz_jpg/xg5dgG6ib5HvUNPjzppqJoI96RndVq0I5btoqBwYUTup10xBKLrqn6tOytDdI2fmVITESz7wzsIONiaDfGCmwvxA/0?wx_fmt=jpeg"
					url="https://open.weixin.qq.com/connect/oauth2/authorize?appid=wx1f5593dd90b59ed3&redirect_uri=http%3a%2f%2fwww.europe-time.cn%2fwechat%2fweixin%2fabstract&response_type=code&scope=snsapi_userinfo&state=STATE#wechat_redirect"
					Rails.logger.info("====credit_gift url : #{url}")
					xbuilder.xml{
						xbuilder.ToUserName{
							xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
							xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
							xbuilder.cdata! "news"
						}
						xbuilder.ArticleCount 1
						xbuilder.Articles {
							xbuilder.item {
								xbuilder.Title{
									xbuilder.cdata! title
								}
								 xbuilder.Description{
									xbuilder.cdata! descp
								}
								xbuilder.PicUrl{
									xbuilder.cdata! picUrl
								}
								xbuilder.Url{
									xbuilder.cdata! url
								}
							}
						}
					}
				elsif event_key=="QRCode"
					logger.info("into QRCode")
					xbuilder.xml{
						xbuilder.ToUserName{
							xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
							xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
							xbuilder.cdata! "event"
						}
						xbuilder.Event {
							xbuilder.cdata! "SCAN"
						}
						xbuilder.EventKey {
							xbuilder.cdata! 224
						}
						xbuilder.Ticket {
							xbuilder.cdata! "gQEY8TwAAAAAAAAAAS5odHRwOi8vd2VpeGluLnFxLmNvbS9xLzAyYmpVVDBZQTlkczMxMDAwMHcwM3AAAgRNCqVYAwQAAAAA"
						}
					}
				end

			elsif event=="VIEW"
				logger.info("into url oauth")
				session[:openid]=params["openid"]
		  	end
		elsif msg_type=="text"
			content=doc.xml.Content.content
			logger.info("content: #{content}")
			if content.upcase.gsub(" ","")=="FXYL"
				if params["openid"].present?
					WeixinShareLog.create(openid: params["openid"],server_type: "overseas",theme: "wechat_share_voucher", status: "failure",log: "FXYL")
					xbuilder.xml{
						xbuilder.ToUserName{
							xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
							xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
							xbuilder.cdata! "text"
						}
						xbuilder.Content {
							xbuilder.cdata! "感谢您的备注! 我们将核实信息后为您赠送折扣券 ！"
						}
					}
				end
			
  			elsif content.gsub(" ","").scan(/[a-zA-Z0-9]{10,20}/)[0]==content.gsub(" ","")
				msg,@parcel,@pd,@ptis=WeixinUserInfo.getTrackingInfoByOverseasHost(content.gsub(" ","").upcase.to_s)
				if @ptis.present?
					pti=@ptis[0]
					pti.each do |time,tracking_info|
						recontent="包裹最新物流信息:\n#{tracking_info.to_s}"
						xbuilder.xml{
							xbuilder.ToUserName{
										xbuilder.cdata! from_username
							}
							xbuilder.FromUserName{
										xbuilder.cdata! to_username
							}
							xbuilder.CreateTime Time.now.to_i
							xbuilder.MsgType {
										xbuilder.cdata! "text"
							}
							xbuilder.Content {
										xbuilder.cdata! recontent
							}
					 	}
					end
				elsif p = Parcel.where("parcel_num like ? or ishpmt_num=?","#{content.gsub(" ","").upcase.to_s}%%",content.gsub(" ","").upcase.to_s).first
					pti=ParcelTrackingInfo.where(parcel_num: p.parcel_num).order('created_at DESC').first
					status_hash= {'returned'=>'入库处理中','on-the-way'=>'运输途中','delivering'=>'投递中','sorted'=>'上网','sent-back'=>'被退回', 'initialized'=>'创建成功', 'in-process'=>'处理中', 'blocked'=>'被拦截','applying-for-cancellation'=>'申请取消','closed'=>'已关闭','cancelled'=>'已取消'}
					recontent="包裹当前状态: #{status_hash[p.max_in_status.to_s]}\n最新物流信息:\n#{pti.tracking_info.to_s}"
					xbuilder.xml{
						xbuilder.ToUserName{
									xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
									xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
									xbuilder.cdata! "text"
						}
						xbuilder.Content {
									xbuilder.cdata! recontent
						}
					}


				else
					xbuilder.xml{
						xbuilder.ToUserName{
									xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
									xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
									xbuilder.cdata! "text"
						}
						xbuilder.Content {
									xbuilder.cdata! "该国际物流号或者包裹编号前14位不存在，请重新输入! "
						}
					}
				end
			else
				time=Time.now
				logger.info("Time.now:#{time}")
				time=Time.now+8.hour if Rails.env.test?
				if time.wday==6||time.wday==0||time<time.beginning_of_day+9.hour||time>time.end_of_day-1.hour
					xbuilder.xml{
						xbuilder.ToUserName{
									xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
									xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
									xbuilder.cdata! "text"
						}
						xbuilder.Content {
									xbuilder.cdata! "您好，已收到您的留言，我们会尽快回复~客服在线时间为：周一至周五 8：00-16：00（节假日除外），请尽量在工作时间内咨询噢~"
						}
				 	}
				
				else
					xbuilder.xml{
						xbuilder.ToUserName{
							xbuilder.cdata! from_username
						}
						xbuilder.FromUserName{
							xbuilder.cdata! to_username
						}
						xbuilder.CreateTime Time.now.to_i
						xbuilder.MsgType {
							xbuilder.cdata! "transfer_customer_service"
						}
					}
				end
			
			end
		end

		logger.info("ret [#{ret_xml}]")
		render plain: ret_xml and return
	end
	#取消关注后的操作
	def release_user(openid)
		WeixinUserInfo.where(wechat_id:openid).update_all(status:"cancelled")
	end						
						
					
	def login
		logger.info("into login")
		#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
		begin
			if session[:openid]==nil
				logger.info("code:#{params[:code]}")
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
			else
				logger.info("非初次绑定")
				logger.info("session[:openid]: #{session[:openid]}")
			end
			emails=[]
			emails=WeixinUserInfo.where(wechat_id: session[:openid],status:"active").map{|wui|wui.email}
			if emails.count>0
				if emails.count==1
					flash[:info]="当前您已绑定并登录帐号: \n#{emails.join}。"
				else
					flash[:info]="您已绑定以下帐号：\n#{emails.join(",")}, 默认自动登录最后一个帐号。"
				end
			end
		rescue=>e
			logger.info("login errors: #{e.message}")
			flash[:login]=e.message
			render "login"
		end
	end

	 def sign_in

		begin
			logger.info("into sign_in")
			logger.info("openid: #{session[:openid]}")
			if params[:email].blank?||params[:password].blank?
				raise "请输入用户名和密码 ! "
			end
			if params[:server].blank?
				raise "请选择业务类型 ! "
			end
			logger.info("邮箱: #{params[:email]}")
			logger.info("密码: #{params[:password]}")
			logger.info("业务类型: #{params[:server]}")
			if (w=WeixinUserInfo.find_by(wechat_id:session[:openid],email: params[:email], password: params[:password], server_type: params[:server])).present?
				if w.status!="active"
					w.update(status:"active")
				end
				
				
				# elsif w.status=="active"&&w.wechat_id!=session[:openid]
				# 	raise "该帐号已在其他设备登录"
				
			else
				if params[:server]=="domestic"  #调用国内服务器
				 	user=User.find_by(email: params[:email])
					if user!=nil
						if user.valid_password?("#{params[:password]}")
							#本人微信绑定用户
							wui=WeixinUserInfo.new
							wui.email=params[:email]
							wui.password=params[:password]
							wui.server_type=params[:server]
							wui.user_id=user.id
							wui.user_nickname=user.nickname
							wui.user_credit=user.obtain_score
							wui.user_rank=Milkvip.get_rank(user)
							wui.user_discount=user.discount
							wui.wechat_id=session[:openid]
							wui.wechat_binding_time=Time.now

							#设置用户标签
							if WeixinUserInfo.where(wechat_id: session[:openid],server_type: params[:server],set_label:"seted").count==0
								begin
									wat=Weixin.get_access_token
									code=Weixin.set_users_label("fba",session[:openid],wat.access_token)
									if code==0
										wui.set_label="seted"
									else
										Weixin.at_exception(wat,code)
										wui.set_label="wait_to_set"
									end
								rescue=> e
									logger.info("openid[#{session[:openid]}] set user label failed")
									wui.set_label="wait_to_set"

								end
							else
								wui.set_label="seted"
							end
							wui.save!
							#redirect_to weixin_home_path
						else
							raise "密码错误 ! "
						end
					else
						raise "用户不存在 !"
					end
				elsif params[:server]=="overseas"  #调用海外服务器
					result,info,msg=WeixinUserInfo.getUserByOverseasHost(params[:email],params[:password])
					if msg==nil
						 if result==true
							wui=WeixinUserInfo.new
							wui.email=params[:email]
							wui.password=params[:password]
							wui.server_type=params[:server]
							wui.user_id=info["id"]
							wui.user_nickname=info["nickname"]
							wui.user_rank=info["rank"]
							wui.user_credit=info["credit"]
							wui.user_discount=info["discount"]
							wui.wechat_id=session[:openid]
							wui.wechat_binding_time=Time.now

							 #设置用户标签
							if WeixinUserInfo.where(wechat_id: session[:openid],server_type: params[:server],set_label:"seted").count==0
								begin
									wat=Weixin.get_access_token
									code=Weixin.set_users_label("mypost4u",session[:openid],wat.access_token)
									if code==0
										wui.set_label="seted"
									else
										Weixin.at_exception(wat,code)
										wui.set_label="wait_to_set"
									end

								rescue=> e
									wui.set_label="wait_to_set"

								end
							else
								wui.set_label="seted"
							end
							wui.save!
							#redirect_to weixin_home_path
						elsif result==false
							raise "密码错误 ! "
						elsif result=="user not exist"
							raise "用户不存在 !"
						end
					else
						raise "访问海外服务器报错: #{msg}"
					end
				end
			end
			if params[:server]=="domestic"
				redirect_to weixin_parcel_list_path
			else
				redirect_to weixin_home_path
			end
		rescue=>e
			logger.info("log_in errors: #{e.message}")
			flash[:login]=e.message
			redirect_to weixin_login_path
		end
	 end

	 def return
	 end

	 def logout

		begin
			logger.info("into logout")
			@user_hash={}
			if session[:openid]==nil
				code=params[:code]
				if code.present?
					oauth2_at,openid=Weixin.get_oauth2_access_token(code)

					if oauth2_at!=""&&openid!=""
						session[:openid]=openid
					else
						raise "get openid failure"
					end
				else
					raise "no code error !"
				end
			end
			wuis=WeixinUserInfo.where(wechat_id: session[:openid],status:"active")

			if wuis.present?
				wuis.each do |user|
					@user_hash[user.email]=user.id
					logger.info("email: #{@user_hash[user.email]}")
				end
			else
				raise "请先登录 !"
			end

		rescue=>e
			logger.info("sign_out errors: #{e.message}")
			flash[:alert]=e.message
		end
	 end

	 def sign_out
		ActiveRecord::Base.transaction do
			begin
				logger.info("into sign_out")
				@importstatus =true
				wui=WeixinUserInfo.find_by(id: params[:user_id])
				wui.update(status:"sleep")
			rescue=>e
				@importstatus = false
				logger.info("sign_out errors: #{e.message}")
				flash[:alert]=e.message
				raise ActiveRecord::Rollback,"rollback!"
			ensure
				if  @importstatus==true
					redirect_to weixin_logout_return_path
				else
					redirect_to weixin_logout_path
				end
			end
		end

	 end

	def logout_return
	end

	 def parcel_search
		logger.info("into parcel_search")
	   
		begin
			if session[:openid]==nil
				code=params[:code]
				if code.present?
					oauth2_at,openid=Weixin.get_oauth2_access_token(code)

					if oauth2_at!=""&&openid!=""
						session[:openid]=openid
					else
						raise "get openid failure"
					end
				else
					raise "no code error !"
				end
			end
			if WeixinUserInfo.where(wechat_id: session[:openid],status:"active").blank?
				raise "请先登录"
			end
		rescue=>e
			logger.info("parcel_search errors: #{e.message}")
			flash[:notice]=e.message
		end
	 end

	 def server_switch
	 	#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
		begin
			if session[:openid]==nil
				code=params[:code]
				if code.present?
					oauth2_at,openid=Weixin.get_oauth2_access_token(code)

					if oauth2_at!=""&&openid!=""
						session[:openid]=openid
					 else
						raise "get openid failure"
					end
				else
					raise "no code error !"
				end
			end

			if (wuis=WeixinUserInfo.where(wechat_id: session[:openid],status:"active")).blank?
				raise "请先登录"
			end

		rescue=>e
			logger.info("server_switch errors: #{e.message}")
			flash[:notice]=e.message
	  	end
	  	render "server_switch"
	end

	def parcel_list
		logger.info("into parcel_list")

		begin
			#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
			#session[:time]=true 代表用户首次进入包裹列表; >false  非首次
			session[:time]=true
			wui=WeixinUserInfo.where(wechat_id: session[:openid],status:"active").last
			if wui.blank?
				redirect_to weixin_login_path, :info=> "请先登录" and return
			end
			if params[:server].present?
				if WeixinUserInfo.where(wechat_id: session[:openid], server_type: params[:server],status:"active").blank?
					redirect_to weixin_server_switch_path, :notice=> "您没有查看#{WeixinUserInfo::BUSSINESS_TYPE[params[:server]]}业务包裹的权限 !" and return
				else
					session[:server]=params[:server] 
				end
			else
				session[:server]=wui.server_type
			end
			Rails.logger.info("session[:server]: #{session[:server]}")
			if session[:server]=="overseas"
				@user_hash={"all"=>""}
				users_all=WeixinUserInfo.where(wechat_id: session[:openid],server_type: session[:server],status:"active")
				users_all.each do |u|
					@user_hash[u.email]=u.user_id
					u.time+=1
					if u.time>1000
						wui.time-=999
					end
					u.save

				end
				if users_all.where("time>1").present?
					session[:time]=false
				end
				if params[:user_id].blank?
					users=users_all
				else
					users=users_all.where(user_id: params[:user_id])
				end
				if params[:page].blank?
					page=1
				else
					page=params[:page].to_i
				end
				Rails.logger.info("page: #{page}")
				msg,@parcelInfo,total_num=WeixinUserInfo.getParcelListByOverseasHost(users.map{|u|u.user_id},params["recipient"],page)
				@total_pages = total_num%4==0 ? (total_num / 4) : (total_num / 4+ 1)
				@parcel_array=[]
				users.each do |u|
					if u.parcel_nums.present?
						@parcel_array+=u.parcel_nums
					end
				end
			elsif session[:server]=="domestic"
				session[:list_user_id] =params[:user_id]
				session[:airwaybill_no] = params[:airwaybill_no]
				session[:time]=true
				redirect_to weixin_parcel_list_fba_path and return
			end
		rescue=>e
			logger.info("parcel_list errors: #{e.message}")
			flash[:notice]=e.message
		end
		render "parcel_list"
	 end

	 def parcel_list_fba
		logger.info("into parcel_list_fba")

		begin
			session[:list_user_id] =params[:user_id]
			session[:time]=true
			@user_hash={"all"=>""}
			users_all=WeixinUserInfo.where(wechat_id: session[:openid],server_type: session[:server],status:"active")
			users_all.each do |u|
				@user_hash[u.email]=u.user_id
				 u.time+=1
				 if u.time>1000
					wui.time-=999
				 end
				 u.save
			end
			if users_all.where("time>1").present?
				session[:time]=false
			end

			if session[:list_user_id].blank?
				users=users_all
			else
				users=users_all.where(user_id: session[:list_user_id])
			end
			
			@airwaybills = Airwaybill.where(parcel_type:"fba",applicant_id: users.map{|u|u.user_id}).where("awb_status ->> 'clrfiles_added' = ? ", "true").where("awb_status ->> 'fltfiles_added' = ? ", "true").where("awb_status ->> 'pcls_added' = ? ", "true")
			if params[:airwaybill_no].present?
	                    @airwaybills = @airwaybills.where(airwaybill_no: params[:airwaybill_no].strip)
	                    flash[:airwaybill_no] = params[:airwaybill_no]
	                end
	                if params[:app_no].present?
	                    @airwaybills = @airwaybills.where(app_no: params[:app_no].strip)
	                    flash[:app_no] = params[:app_no]
	                end
	                if params[:parcel_type].present?
	                    @airwaybills = @airwaybills.where(parcel_type: params[:parcel_type])
	                    flash[:parcel_type] = params[:parcel_type]
	                end
	                if params[:flight_time_begin].present?
	                    @airwaybills = @airwaybills.where("flight_time >= :begin", {begin: params[:flight_time_begin].to_i})
	                    flash[:flight_time_begin] = params[:flight_time_begin]
	                end
	                if params[:flight_time_end].present?
	                    @airwaybills = @airwaybills.where("flight_time <= :end", {end: params[:flight_time_end].to_i})
	                    flash[:flight_time_end] = params[:flight_time_end]
	                end
			@airwaybills = @airwaybills.paginate(:page => params[:page], :per_page => 20).order('created_at DESC')
		rescue=>e
			logger.info("parcel_list_fba errors: #{e.message}")
			flash[:notice]=e.message
		end
		render "parcel_list_fba"

	 end

	 def tracking_info_fba
		logger.info("into tracking_info_fba")

		begin
			if params[:server].present?
				if (user_ids=WeixinUserInfo.where(wechat_id: session[:openid],server_type: params[:server],status:"active").map{|u|u.user_id}).blank?
					redirect_to weixin_parcel_search_path, :notice=> "您没有查询#{WeixinUserInfo::BUSSINESS_TYPE[params[:server]]}业务包裹的权限 !" and return
				else
					session[:user_ids]=user_ids
				end

				if params[:server]=="overseas" #mypost4u
					if params[:parcel_no].present?  #来源: 包裹查询页面
						session[:parcel_no]=params[:parcel_no]
					else        #来源: 包裹列表页面
						session[:parcel_no]=params[:id]
					end

					redirect_to tracking_info_path and return

				elsif params[:server]=="domestic"

					if params[:parcel_no].present?  #来源: 包裹查询页面
						@parcel = Parcel.where(parcel_owner: user_ids).where("parcel_num like ? or ishpmt_num=?","#{params[:parcel_no]}%%",params[:parcel_no]).first
						if @parcel.present?
							@pd=ParcelDetail.find_by(parcel_num: @parcel.parcel_num)
							@ptis = ParcelTrackingInfo.where(parcel_num: @parcel.parcel_num).order('created_at DESC')
						end
					else        #来源: 包裹列表页面
						@parcel=Parcel.find_by(parcel_num: params[:id])
							if @parcel.present?
								@pd=ParcelDetail.find_by(parcel_num: @parcel.parcel_num)
								@ptis = ParcelTrackingInfo.where(parcel_num: @parcel.parcel_num).order('created_at DESC')
							end
					end
				end


			elsif session[:server]=="overseas"
				if params[:parcel_no].present?  #来源: 包裹查询页面
					session[:parcel_no]=params[:parcel_no]
				else                                                  #来源: 包裹列表页面
					session[:parcel_no]=params[:id]
				end
				redirect_to tracking_info_path and return

			  elsif session[:server]=="domestic"
				if params[:parcel_no].present?  #来源: 包裹查询页面
					@parcel = Parcel.where("parcel_num like ? or ishpmt_num=?","#{params[:parcel_no]}%%",params[:parcel_no]).first
					@pd=ParcelDetail.find_by(parcel_num: @parcel.parcel_num)
					@ptis = ParcelTrackingInfo.where(parcel_num: @parcel.parcel_num).order('created_at DESC')
				else                                                #来源: 包裹列表页面
					@parcel=Parcel.find_by(parcel_num: params[:id])
					@pd=ParcelDetail.find_by(parcel_num: @parcel.parcel_num)
					@ptis = ParcelTrackingInfo.where(parcel_num: @parcel.parcel_num).order('created_at DESC')
				end
			   end
		rescue=>e
			logger.info("parcel_list_fba errors: #{e.message}")
		end
		render "tracking_info_fba"
	end

	 def tracking_info
		logger.info("into tracking_info")

		msg,@parcel,@pd,@ptis=WeixinUserInfo.getTrackingInfoByOverseasHost(session[:parcel_no])
		if msg.present?
			flash[:notice] = msg
			redirect_back(fallback_location: root_path) and return
		end
	end

	def parcel_follow
		logger.info("into parcel_follow")
		ActiveRecord::Base.transaction do
			begin
				if params["server"].blank? || session[:openid].blank?
					raise "页面失效，请刷新"
				end
				wui = WeixinUserInfo.where(server_type: params["server"],user_id: params["parcel_owner"],status:"active").first
				wui.parcel_nums<<params["parcel_num"]
				wui.save
				render json: { status:'success'}.to_json
			rescue=>e
				logger.info("parcel_follow errors: #{e.message}")
				raise ActiveRecord::Rollback,"rollback!"
				render json: { status:'failure', reason:e.message}.to_json
			end
	  	end
	end

	def parcel_follow_cancel
		logger.info("into parcel_follow_cancel")
		ActiveRecord::Base.transaction do
			begin
				if params["server"].blank? || session[:openid].blank?
					raise "页面失效，请刷新"
				end
				wui = WeixinUserInfo.where(server_type: params["server"],user_id: params["parcel_owner"],status:"active").first
				wui.parcel_nums.delete(params["parcel_num"]) unless !(wui.parcel_nums.include?(params["parcel_num"]))
				wui.save
				render json: { status:'success'}.to_json
			rescue=>e
				logger.info("parcel_follow_cancel errors: #{e.message}")
				raise ActiveRecord::Rollback,"rollback!"
				render json: { status:'failure', reason:e.message}.to_json
			end
	   	end
	end

	#分享有礼: 每个微信用户限一次，3欧元=200积分
	def credit_gift
		logger.info("into credit_gift")
		begin
			logger.info("credit_gift session.openid:[#{session[:openid]}] ; ")
			sl=WeixinShareLog.create(openid: params[:openid],server_type: "overseas",theme: "wechat_share_gift")
			wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: params[:openid],status:"active").last
			if wui.present?
				wui.share_num+=1
				wui.save
				status,msg=WeixinUserInfo.creditByOverseasHost(wui.email,"wechat_share_gift","200")
				sl.wui_owner=wui.id
				sl.status=status
				sl.log=msg
				sl.save
				render json: { status: status, reason: msg}.to_json
			else
				sl.status="success"
				sl.log="未查到已绑定的mypost4u帐号，我们无法为您赠送积分。"
				sl.save
				render json: { status: "success", reason: "未查到已绑定的mypost4u帐号，我们无法为您赠送积分。"}.to_json
			end
					  
		rescue=>e
			sl.status="failure"
			sl.log=e.message
			sl.save
			logger.info("credit_gift errors: #{e.message}")
			render json: { status:'failure', reason:e.message}.to_json
	   	end
	end

	def abstract
		begin
			logger.info("into abstract")
			#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
			if session[:openid]==nil
				logger.info("abstract code:#{params[:code]}")
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
			@openid=session[:openid]
			@jsapi=Weixin.jsapi_ticket
			Rails.logger.info("abstract openid: [#{@openid}]/jsapi: [#{@jsapi}]")
			@appid=Weixin::APPID
			   
		rescue=>e
			Rails.logger.info("abstract rescue: openid=[#{@openid}]/jsapi=[#{@jsapi}]")
			logger.info("abstract errors: #{e.message}")
		end
	end


	def commodity_add
		begin
			logger.info("into ygbs commodity_add")
			@wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
			if @wui.blank?
				raise "请先登录!"
			end
			if params["barcodes"].blank?
				raise "添加商品不能为空!"
			end
			logger.info("barcode :#{params["barcodes"].split(";")}")
			@status,@msg,@info=RegisterList.rlByOverseasHost(@wui.email,params["barcodes"].split(";"))
					  
		rescue=>e
			Rails.logger.info("commodity_add rescue: openid=#{session[:openid]}")
			logger.info("commodity_add errors: #{e.message}")
			@msg=e.message
		end
		redirect_to weixin_scan_barcode_path,:notice=>@msg
	end
	#mypost4u首页
	def home
		begin 
			#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
			logger.info("into home")
			session[:server]="overseas"
			if session[:openid]==nil
				 logger.info("home code:#{params[:code]}")
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
			@wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
			if @wui
				@credit=@wui.obtain_score
				if @credit!=@wui.user_credit
					@wui.user_credit=@credit
					@wui.save
				end
			end		   
		rescue=>e
			logger.info("home errors: #{e.message}")
		end
	end

	def scan_barcode
		begin
		#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
			logger.info("into scan_barcode")
			if session[:openid]==nil
				logger.info("scan_barcode code:#{params[:code]}")
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
			@openid=session[:openid]
			@jsapi=Weixin.jsapi_ticket
			Rails.logger.info("scan_barcode openid: [#{@openid}]/jsapi: [#{@jsapi}]")
			@appid=Weixin::APPID
					   
		rescue=>e
			Rails.logger.info("scan_barcode rescue: openid=[#{@openid}]/jsapi=[#{@jsapi}]")
			logger.info("scan_barcode errors: #{e.message}")
		end
	end

	def get_credit
		begin
			#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
			logger.info("into get_credit")
			wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
			@credit=wui.obtain_score
			if @credit!=wui.user_credit
				wui.user_credit=@credit
				wui.save
			end
			logger.info("#{@credit!=wui.user_credit}")
			render json: { status: "success", reason: wui.user_credit}.to_json
		rescue=>e
			logger.info("get_credit errors: #{e.message}")
			render json: { status:'failure', reason:e.message}.to_json
		end
	end

	def construction
		openid,msg=get_session_openid
		if openid.present?
			@openid=openid
			@jsapi=Weixin.jsapi_ticket
			Rails.logger.info("construction openid: [#{@openid}]/jsapi: [#{@jsapi}]")
			@appid=Weixin::APPID
		end
	end

	def get_session_openid
		#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
		msg=""
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
	      	rescue=>e
	      		logger.info("get_session_openid errors: #{e.message}")
	      		msg=e.message
	    	end
	    	[session[:openid],msg]
	end

	def production_intr_fba
	end
	
	def registration
	end
	def check_email
		status="failure"
		info=""
		if params[:email].present?
			status,msg,info=WeixinUserInfo.getEmailValidateByOverseasHost(params[:email])
			if msg.present?
				Rails.logger.info("check_email error:#{msg}")
			end
		end
		session[:code]=info["varify_code"]
		session[:time]=info["expired_time"]
		render json: { status:status,info:info }.to_json
	end
	#注册
	def register
		begin
			Rails.logger.info("into register")
			@message=""
			@status=false
			@user = User.new
			msg=[]
			msg=check_register_params(params)
			if msg.blank?
				status,info=WeixinUserInfo.getRegisterByOverseasHost(params["email"],params["nickname"],params["password"],"wechat")
				if status=="success"
					@status=true
					session[:code]=nil
					session[:time]=nil
				else
					@message=info
					flash[:info]=@message
				end
			else
				@message=msg.join("; ")
				flash[:info]=@message
			end
		rescue => e
			@message=e.message
			Rails.logger.info("register rescue:#{@message}")
		ensure
			if @status==false
				render :registration
			else
				redirect_to weixin_login_path and return
			end
		end
		
	end

	def check_register_params(params)
		msg=[]

		if params["email"].blank?
			msg<<"邮箱不能为空"
		end
		if params["verification_code"].blank?
			msg<<"验证码不能为空"
		elsif params["code"].blank?
			msg<<"验证码错误"
		elsif params["time"].blank?
			msg<<"验证码错误"
		end
		if params["nickname"].blank?
			msg<<"用户名不能为空"
		end
		if params["password"].blank?
			msg<<"密码不能为空"
		elsif params["password"].gsub(" ","").size<8
			msg<<"密码至少8位"
		end
		
		if params["verification_code"].present?&&params["code"].present?
			if Digest::MD5.hexdigest(params["verification_code"])!=params["code"]
				Rails.logger.info("verification_code wrong")
				msg<<"验证码错误"
			elsif params["time"].present?&&Time.parse(params["time"].to_s)<Time.now
				Rails.logger.info("verification_code time expired")
				msg<<"验证码错误"
			end
		end
		@user.email=params["email"]
		@user.nickname=params["nickname"]
		@user.customer_num=params["verification_code"] #暂存验证码
		msg
	end

	protected
	def auth_user
	    	#session[:openid]="o-1VYwucgSpd2kqPKfq1H71rSzoY"
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
	      		
	    	rescue=>e
	      		logger.info("auth_user errors: #{e.message}")
	    	end
	    	session[:openid]
	end

end
end
