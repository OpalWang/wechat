Rails.application.routes.draw do

  mount Wechat::Engine => "/wechat"
end
