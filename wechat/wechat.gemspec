$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "wechat/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "wechat"
  s.version     = Wechat::VERSION
  s.authors     = ["OpalWang"]
  s.email       = ["huaeryuemo@outlook.com"]
  s.homepage    = "http://www.wechat.com"
  s.summary     = "Wechat Function"
  s.description = "Wechat Function"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 5.1.4"
  s.add_dependency "roo", "~> 2.1.1"
  s.add_dependency "combine_pdf", '~> 0.2.5'
  s.add_dependency 'spreadsheet', '~> 1.1'

  s.add_development_dependency "sqlite3"
end
 