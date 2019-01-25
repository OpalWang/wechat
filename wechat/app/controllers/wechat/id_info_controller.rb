module Wechat
class IdInfoController < ApplicationController
    layout "layouts/wechat/application"
    protect_from_forgery
    skip_before_action :verify_authenticity_token, :only =>["create","update"]
    before_action :auth_user
    PER_PAGE = 5
    def new
        @id_num=params["id_num"]
        @telephone=params["telephone"]
    end
    def create
        ActiveRecord::Base.transaction do
        begin
            @importstatus=true
            @msg=nil
            @id_num=params["id_num"]
            @telephone=params["telephone"]
            if params["uploaderInput"].blank?
                raise "请上传身份证正面图片"
            end
            if params["uploaderInput1"].blank?
                raise "请上传身份证反面图片"
            end
             if id_info=Wechat::IdInfo.where(owner: @wui.user_id, id_num: @id_num).first
             else
                id_info = Wechat::IdInfo.new(owner: @wui.user_id, id_num: @id_num)
            end
             id_info.status="applying"
             id_info.id_card_front=params["uploaderInput"]
             id_info.id_card_back=params["uploaderInput1"]
             id_info.telephone=params["telephone"]
             id_info.save!
        rescue => e
            @importstatus=false
            @msg=e.message
            Rails.logger.info("id_info create failure:#{e.message}")
            raise ActiveRecord::Rollback,"rollback!"
        ensure
                        if @importstatus
                            redirect_to id_info_show_path(id_num:@id_num,telephone:@telephone)
                        else
                            flash[:notice]=@msg
                            render :new
                        end
        end
        end
    end

    def edit
        @id=params["id"]
        @id_info = Wechat::IdInfo.find(@id) 
            
    end

    def update
        ActiveRecord::Base.transaction do
        begin
            @importstatus=true
            @msg=nil
            @id=params["id"]
            @id_info = Wechat::IdInfo.find(@id) 
             
            if params["uploaderInput"].blank?&&params["uploaderInput1"].blank?
            else
                @id_info.status="applying"
                if params["uploaderInput"].present?
                    @id_info.id_card_front=params["uploaderInput"]
                else
                    @id_info.id_card_front=@id_info.id_card_front
                end
                if params["uploaderInput1"].present?
                    @id_info.id_card_back=params["uploaderInput1"]
                else
                    @id_info.id_card_back=@id_info.id_card_back
                end
                @id_info.save!
            end
             
        rescue => e
            @importstatus=false
            @msg=e.message
            Rails.logger.info("id_info update failure:#{e.message}")
            raise ActiveRecord::Rollback,"rollback!"
        ensure
                        if @importstatus
                            redirect_to id_info_show_path(id_num:@id_info.id_num,telephone:@id_info.telephone)
                        else
                            flash[:notice]=@msg
                            render :edit
                        end
        end
        end
    end

    def show
        @ids=Wechat::IdInfo.where(id_num:params["id_num"],telephone:params["telephone"],owner:@wui.user_id)
    end
   
    def delete
        @id_info= Wechat::IdInfo.find(params[:id])
        @num=@id_info.id_num
        @telephone=@id_info.telephone
        @id_info.destroy
        redirect_to id_info_show_path(id_num:@num,telephone:@telephone)
    end

    protected
            def auth_user
                   begin
                        #session[:openid]='oJAlcw83X9NPAAwshp3oeHvZFZF4'
                        if session[:openid]==nil
                            raise "No openid !"
                        else
                            @wui= WeixinUserInfo.where(server_type: "overseas",wechat_id: session[:openid],status:"active").last
                            if @wui.blank?
                                raise "No active WeixinUserInfo With #{session[:openid]} !"
                            end
                        end
                    rescue=>e
                            logger.info("auth_user errors: #{e.message}")
                            redirect_to weixin_home_path
                    end
        end
end
end
