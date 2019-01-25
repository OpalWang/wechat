Wechat::Engine.routes.draw do
  devise_for :users, module: :devise, controllers: { registrations: "registrations" }
  root to:  "weixin#login"
  

  get 'weixin'=>"weixin#auth"
  post 'weixin'=>"weixin#menu"
  get 'weixin/server_switch'=>"weixin#server_switch"
  get 'weixin/parcel_list'=>"weixin#parcel_list"
  get 'weixin/parcel_list_fba'=>"weixin#parcel_list_fba"
  post 'weixin/parcel_follow'=>"weixin#parcel_follow"
  post 'weixin/parcel_follow_cancel'=>"weixin#parcel_follow_cancel"
  get 'weixin/parcel_search'=>"weixin#parcel_search"
  get 'weixin/tracking_info/:id', to: "weixin#tracking_info",as: 'tracking_info'
  get 'weixin/tracking_info_fba/:id', to: "weixin#tracking_info_fba",as: 'tracking_info_fba'
  get 'weixin/login'=> "weixin#login"
  post 'weixin/sign_in'=> "weixin#sign_in"
  get 'weixin/return'=>"weixin#return"
  get 'weixin/logout'=>"weixin#logout"
  post 'weixin/sign_out'=> "weixin#sign_out"
  get 'weixin/logout_return'=>"weixin#logout_return"
  get 'weixin/introduction'=>"weixin#introduction"
  get 'weixin/instruction'=>"weixin#instruction"
  get 'weixin/production_intr'=>"weixin#production_intr"
  get 'weixin/sharing'=>"weixin#sharing"
  post 'weixin/credit_gift'=>"weixin#credit_gift"
  get 'weixin/construction'=>"weixin#construction"
  get 'weixin/abstract'=>'weixin#abstract'
  get 'weixin/scan_barcode'=>'weixin#scan_barcode'
  post 'weixin/commodity_add'=>'weixin#commodity_add'
  get 'weixin/home'=>'weixin#home'
  post 'weixin/get_credit'=>"weixin#get_credit"
  get 'weixin/production_intr_fba'=>"weixin#production_intr_fba"
  get 'weixin/official_accounts_intr'=>"weixin#official_accounts_intr"
  get 'weixin/registration'=>"weixin#registration"
  post 'weixin/register'=>"weixin#register"
  post 'weixin/check_email'=>"weixin#check_email"
#地址管理
  get 'active_address/add_recipient_address'=>'active_address#add_recipient_address'
  get 'active_address/add_sender_address'=>'active_address#add_sender_address'
  get 'active_address/sender_address_info'=>'active_address#sender_address_info'
  get 'active_address/recipient_address_info'=>'active_address#recipient_address_info'
  post 'active_address/sndr_address_create'=>'active_address#sndr_address_create'
  post 'active_address/rcpt_address_create'=>'active_address#rcpt_address_create'
  get 'active_address/edit_sndr_address'=>'active_address#edit_sndr_address'
  get 'active_address/edit_rcpt_address'=>'active_address#edit_rcpt_address'
  post 'active_address/update_sndr_address'=>'active_address#update_sndr_address'
  post 'active_address/update_rcpt_address'=>'active_address#update_rcpt_address'
  get 'active_address/sndr_select'=>"active_address#sndr_select"
  get 'active_address/rcpt_select'=>"active_address#rcpt_select"
  get 'active_address/reset_rcpt_address'=>"active_address#reset_rcpt_address"
  get 'active_address/reset_sndr_address'=>"active_address#reset_sndr_address"
  get 'active_address/delete_rcpt_address'=>"active_address#delete_rcpt_address"
  get 'active_address/delete_sndr_address'=>"active_address#delete_sndr_address"
  #下单
  get 'parcel/add_commodity'=>"parcel#add_commodity"
  post 'parcel/commodity_create'=>"parcel#commodity_create"
  get 'parcel/ygbs_new'=>"parcel#ygbs_new"
  get 'parcel/delete_rl'=>"parcel#delete_rl"
  post 'parcel/postal_create'=>"parcel#postal_create"
  get 'parcel/order_preview'=>"parcel#order_preview"
  post 'parcel/order_list'=>"parcel#order_list"
  post 'parcel/calculate_price'=>"parcel#calculate_price"
  post 'parcel/set_quantity'=>"parcel#set_quantity"
  get 'parcel/nfzx_new'=>"parcel#nfzx_new"
  post 'parcel/add_commodity_nfzx'=>"parcel#add_commodity_nfzx"
  get 'parcel/delete_ml'=>"parcel#delete_ml"
  post 'parcel/change_quantity'=>"parcel#change_quantity"
  get 'parcel/pay'=>"parcel#pay"
  get 'parcel/wait_pay'=>"parcel#wait_pay"
  get 'parcel/posting_file'=>"parcel#posting_file"
  #支付
  get 'parcel_payment/new'=>"parcel_payment#new"
  post 'parcel_payment/credit_pay'=>"parcel_payment#credit_pay"
  get 'parcel_payment/oceanpay_redirect'=>"parcel_payment#oceanpay_redirect"
  post 'parcel_payment/gen_second_sign'=>"parcel_payment#gen_second_sign"
  post 'parcel_payment/pre_wxpay'=>"parcel_payment#pre_wxpay"
  post 'parcel_payment/cancel'=>"parcel_payment#cancel"
  post 'parcel_payment/wxpay_redirect'=>"parcel_payment#wxpay_redirect"
  post 'parcel_payment/coupon_exchange'=>"parcel_payment#coupon_exchange"
  post 'parcel_payment/coupon_restore'=>"parcel_payment#coupon_restore"
  #IdInfo
  get 'id_info/show'=>"id_info#show"
  get 'id_info/new'=>"id_info#new"
  post 'id_info/create'=>"id_info#create"
  get 'id_info/delete'=>"id_info#delete"
  get 'id_info/edit'=>"id_info#edit"
  post 'id_info/update'=>"id_info#update"

end
