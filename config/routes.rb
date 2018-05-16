Rails.application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  get 'second_demo/index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  

  #微信Call
   post '/weixin/push_foreign_user_info' => "merchant_private_api#push_foreign_user_info"
   post '/weixin/push_foreign_tracking_info' => "merchant_private_api#push_foreign_tracking_info"
   post '/weixin/push_foreign_parcel_list' =>"merchant_private_api#push_foreign_parcel_list"
   post '/weixin/push_timing_tracking_info' => "merchant_private_api#push_timing_tracking_info"
   post '/weixin/get_share_gift' => "merchant_private_api#push_share_gift"
   post '/weixin/get_commodity_info' => "merchant_private_api#push_commodity_info"
   post '/weixin/push_ygbs_barcode' =>"merchant_private_api#push_ygbs_barcode"
   post '/weixin/push_commodity_info'=>"merchant_private_api#push_commodity_info"
   post '/weixin/update_user_rank' =>"merchant_private_api#update_user_rank"
   post '/weixin/update_user_info' =>"merchant_private_api#update_user_info"
   post 'weixin/push_nfzx_milkinfo'=>"merchant_private_api#push_nfzx_milkinfo"
   post 'weixin/wechat_pay'=>"merchant_private_api#wechat_pay"
   post 'weixin/push_unpaid_parcels'=>"merchant_private_api#push_unpaid_parcels"
   post 'weixin/push_mypost4u_message'=>"merchant_private_api#push_mypost4u_message"

  
  mount Wechat::Engine, at: "/wechat"





  scope '(:locale)' do
    devise_for :users, controllers: { registrations: "registrations" }
    #root to: "demo#index"
    #get 'home', to: 'demo#index'
    #get 'package_center', to: 'demo#package_center'
    #resources :parcels, only: [:index, :show]
    #resources :parcel_contracts, only: [:index]
  end
end
