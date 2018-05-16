module Wechat
class ActiveAddressController < ApplicationController
            layout "layouts/wechat/application"
            protect_from_forgery
              skip_before_action :verify_authenticity_token, :only =>["sndr_address_create","rcpt_address_create","update_sndr_address","update_rcpt_address"]
    before_action :auth_user
    PER_PAGE = 5
    #收件
    def recipient_address_info
        begin
            wui=WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
            @rcp_adrs=Wechat::ActiveAddress.where(parcel_owner: wui.user_id,usage_type:"recipient").order('default_flag DESC,created_at DESC')

        rescue => e
            Rails.logger.info("recipient_address_info rescue: #{e.message} ")
            flash[:notice]=e.message
        end

    end
    def rcpt_select
        begin
            wui=WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
            @rcp_adrs=Wechat::ActiveAddress.where(parcel_owner: wui.user_id,usage_type:"recipient",country:"cn").order('default_flag DESC,created_at DESC')

        rescue => e
            Rails.logger.info("rcpt_select rescue: #{e.message} ")
            flash[:notice]=e.message
        end
    end
    def add_recipient_address
        if params["type"].present?
            if params["type"]=="ygbs_new"
                session["rcpt_create"]="ygbs_new"
            elsif params["type"]=="nfzx_new"
                session["rcpt_create"]="nfzx_new"
            end

        end
        @address=Wechat::ActiveAddress.new
    end
    def rcpt_address_create
        ActiveRecord::Base.transaction do
            begin
                        @import_msg = []
                        @importstatus = true
                        wui=WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                        if wui.blank?
                            raise "未找到登录用户"
                        end
                        @address = Wechat::ActiveAddress.new
                        @address.country = params[:country]
                        @address.name = params[:name]
                        @address.province = params[:province]
                        @address.city = params[:city]
                        @address.district = params[:district]
                        @address.street = params[:street]
                        @address.postcode = params[:postcode]
                        @address.telephone = params[:telephone]
                        @address.email = params[:email]
                        @address.id_number = params[:id_number]
                        @address.usage_type = "recipient"
                        @address.parcel_owner = wui.user_id
                        #确保默认地址只有一个(最后操作为准)
                        if params[:default_flag]
                            if (da=Wechat::ActiveAddress.where(parcel_owner:wui.user_id,usage_type:"recipient",default_flag: true)).present?
                                da.update(default_flag: false)
                            end
                            @address.default_flag=true
                        end
                        msg=CheckApiParams.mypost4u_check_recipient_address_params(params)

                        if msg.present?
                                @importstatus = false
                                @import_msg = msg
                        else
                                 @address.save!
                        end
            rescue=>e
                        @import_msg = [e.message] unless @import_msg.present?
                        @importstatus = false
                        Rails.logger.info("recipient address create failure:#{e.message}")
                        raise ActiveRecord::Rollback,"rollback!"
            ensure
                        if @importstatus
                                if session["rcpt_create"].present?&&session["rcpt_create"]=="ygbs_new"
                                    session["rcpt_create"]=nil
                                    redirect_to parcel_ygbs_new_path
                                elsif session["rcpt_create"].present?&&session["rcpt_create"]=="nfzx_new"
                                    session["rcpt_create"]=nil
                                    redirect_to parcel_nfzx_new_path
                                else
                                    flash[:notice] = "添加成功" unless flash[:notice]
                                    redirect_to active_address_recipient_address_info_path
                                end
                        else

                            flash[:notice] = @import_msg
                                render :add_recipient_address
                        end
            end
        end
    end

    def edit_rcpt_address
                @address=Wechat::ActiveAddress.find(params["id"])
    end

    def update_rcpt_address
                ActiveRecord::Base.transaction do
                    begin
                                @import_msg = []
                                @importstatus = true
                                @address = Wechat::ActiveAddress.find(params[:id])
                                @address.name = params[:name]
                                @address.province = params[:province]
                                @address.city = params[:city]
                                @address.district = params[:district]
                                @address.street = params[:street]
                                @address.postcode = params[:postcode]
                                @address.telephone = params[:telephone]
                                @address.email = params[:email]
                                @address.id_number = params[:id_number]

                                #确保默认地址只有一个(最后操作为准)
                                if params[:default_flag]
                                        if (da=Wechat::ActiveAddress.where(parcel_owner:@address.parcel_owner,usage_type:"recipient",default_flag: true)).present?
                                                da.update(default_flag: false)
                                        end
                                        @address.default_flag=true
                                else
                                        @address.default_flag=false
                                end

                            msg=CheckApiParams.mypost4u_check_recipient_address_params(params)
                            if msg.present?
                                        @importstatus = false
                                        @import_msg = msg
                            else
                                            @address.save!
                            end
                    rescue=>e
                            @import_msg = [e.message] unless @import_msg.present?
                            @importstatus = false
                            Rails.logger.info("rcpt address update failure:#{e.message}")
                            raise ActiveRecord::Rollback,"rollback!"
                    ensure
                                if @importstatus
                                        flash[:notice] = "编辑成功" unless flash[:notice]
                                        redirect_to active_address_recipient_address_info_path
                                else
                                        flash[:notice] = @import_msg
                                        render :edit_rcpt_address
                                end
                    end
                end
    end

    def reset_rcpt_address
        session[:rcpt_id]=params["rcpt_id"]
        rcpt=Wechat::ActiveAddress.find(params["rcpt_id"])
        session[:rcpt_name]=rcpt.name
        session[:rcpt_tele]=rcpt.telephone
        session[:rcpt_address]=rcpt.getInfo["address_combine"]

        if session[:shpmt_product]=="阳光包税专线"
            redirect_to wechat.parcel_ygbs_new_path
        elsif session[:shpmt_product]=="NFZX"
            redirect_to wechat.parcel_nfzx_new_path
        end

    end

    def delete_rcpt_address
        address = ActiveAddress.find(params[:id])
            address.destroy
            redirect_to active_address_recipient_address_info_path
    end

        #寄件
        def sender_address_info
                    begin
                        wui=WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                        @sdr_adrs=Wechat::ActiveAddress.where(parcel_owner: wui.user_id,usage_type:"sender").order('default_flag DESC,created_at DESC')
                rescue => e
                        Rails.logger.info("recipient_address_info rescue: #{e.message} ")
                        flash[:notice]=e.message
                end
        end

        def sndr_select
                begin
                        wui=WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                        @sdr_adrs=Wechat::ActiveAddress.where(parcel_owner: wui.user_id,usage_type:"sender",country:"de").order('default_flag DESC,created_at DESC')
                rescue => e
                        Rails.logger.info("sndr_select rescue: #{e.message} ")
                        flash[:notice]=e.message
                end
        end

    def add_sender_address
        if params["type"].present?
            if params["type"]=="ygbs_new"
                session["sndr_create"]="ygbs_new"
            elsif params["type"]=="nfzx_new"
                session["sndr_create"]="nfzx_new"
            end
        end
        @address=Wechat::ActiveAddress.new
    end
    def sndr_address_create
        ActiveRecord::Base.transaction do
            begin
                        @import_msg = []
                        @importstatus = true
                        wui=WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                        if wui.blank?
                            raise "未找到登录用户"
                        end
                        @address = Wechat::ActiveAddress.new
                        @address.country = params[:country]
                        @address.name = params[:name]
                        @address.house_num = params[:house_num]
                        @address.city = params[:city]
                        @address.street = params[:street]
                        @address.postcode = params[:postcode]
                        @address.telephone = params[:telephone]
                        @address.email = params[:email]
                        @address.usage_type = "sender"
                        @address.parcel_owner = wui.user_id
                        #确保默认地址只有一个(最后操作为准)
                        if params[:default_flag]
                            if (da=Wechat::ActiveAddress.where(parcel_owner:wui.user_id,usage_type:"sender",default_flag: true)).present?
                                da.update(default_flag: false)
                            end
                            @address.default_flag=true
                        end
                        msg=CheckApiParams.mypost4u_check_sender_address_params(params)
                        if msg.present?
                                @importstatus = false
                                @import_msg = msg
                        else
                                 @address.save!
                        end
            rescue=>e
                        @import_msg = [e.message] unless @import_msg.present?
                        @importstatus = false
                        Rails.logger.info("sender address create failure:#{e.message}")
                        raise ActiveRecord::Rollback,"rollback!"
            ensure
                        if @importstatus
                            if session["sndr_create"].present?&&session["sndr_create"]=="ygbs_new"
                                    session["sndr_create"]=nil
                                    redirect_to parcel_ygbs_new_path
                                elsif session["sndr_create"].present?&&session["sndr_create"]=="nfzx_new"
                                    session["sndr_create"]=nil
                                    redirect_to parcel_nfzx_new_path
                                else
                                    flash[:notice] = "添加成功" unless flash[:notice]
                                    redirect_to active_address_sender_address_info_path
                                end
                        else
                            flash[:notice] = @import_msg
                                render :add_sender_address
                        end
            end
        end
    end

    def edit_sndr_address
            @address=Wechat::ActiveAddress.find(params["id"])
    end

    def update_sndr_address
         ActiveRecord::Base.transaction do
                    begin
                                @import_msg = []
                                @importstatus = true
                                @address = Wechat::ActiveAddress.find(params[:id])
                                @address.name = params[:name]
                                @address.house_num = params[:house_num]
                            @address.city = params[:city]
                                @address.street = params[:street]
                                @address.postcode = params[:postcode]
                                @address.telephone = params[:telephone]
                                @address.email = params[:email]

                                #确保默认地址只有一个(最后操作为准)
                                if params[:default_flag]
                                        if @address.default_flag!=true
                                                Wechat::ActiveAddress.where(parcel_owner:@address.parcel_owner,usage_type:"sender",default_flag: true).each do |a|
                                                    a.update(default_flag: false)
                                                end
                                        end
                                        @address.default_flag=true
                                else
                                    if @address.default_flag==true
                                                @address.default_flag=false
                                        end
                                end

                                msg=CheckApiParams.mypost4u_check_sender_address_params(params)
                                if msg.present?
                                        @importstatus = false
                                        @import_msg = msg
                                else
                                            @address.save!
                                end
                    rescue=>e
                                @import_msg = [e.message] unless @import_msg.present?
                                @importstatus = false
                                Rails.logger.info("rcpt address update failure:#{e.message}")
                                raise ActiveRecord::Rollback,"rollback!"
                    ensure
                                    if @importstatus
                                            flash[:notice] = "编辑成功" unless flash[:notice]
                                            redirect_to active_address_sender_address_info_path
                                    else
                                            flash[:notice] = @import_msg
                                            render :edit_sndr_address
                                    end
                    end
        end
    end

    def reset_sndr_address
        session[:sndr_id]=params["sndr_id"]
        sndr=Wechat::ActiveAddress.find(params["sndr_id"])
        session[:sndr_name]=sndr.name
        session[:sndr_tele]=sndr.telephone
        session[:sndr_address]=sndr.getInfo["address_combine"]
        if session[:shpmt_product]=="阳光包税专线"
            redirect_to wechat.parcel_ygbs_new_path
        elsif session[:shpmt_product]=="NFZX"
            redirect_to wechat.parcel_nfzx_new_path
        end
    end

    def delete_sndr_address
        address = ActiveAddress.find(params[:id])
            address.destroy
            redirect_to active_address_sender_address_info_path
    end

    protected
            def auth_user
                    begin
                            #session[:openid]='123'
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