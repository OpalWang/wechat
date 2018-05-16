# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( wechat/style.css )
Rails.application.config.assets.precompile += %w( wechat/login.css )
Rails.application.config.assets.precompile += %w( wechat/parcel.css )
Rails.application.config.assets.precompile += %w( wechat/awb.css )
Rails.application.config.assets.precompile += %w( wechat/framework.css )
Rails.application.config.assets.precompile += %w( wechat/weui.mini.css )
Rails.application.config.assets.precompile += %w( wechat/jquery_mobile.js )
Rails.application.config.assets.precompile += %w( wechat/milk_brand.js )
Rails.application.config.assets.precompile += %w( sha1.js )
Rails.application.config.assets.precompile += %w( wechat/weixin.js )
Rails.application.config.assets.precompile += %w( qrcode.mini.js )

Rails.application.config.assets.precompile += %w( bootstrap.min.css )
Rails.application.config.assets.precompile += %w( bootstrap.min.js )
Rails.application.config.assets.precompile += %w( jquery.min.js )

Rails.application.config.assets.precompile += %w( ckeditor/* )
