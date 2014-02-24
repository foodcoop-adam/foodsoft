$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_userinfo/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_userinfo"
  s.version     = FoodsoftUserinfo::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoop-adam/foodsoft"
  s.summary     = "Basic userinfo endpoint for foodsoft."
  s.description = "Allow external systems to authenticate using foodsoft via a userinfo endpoint."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "README.md"]

  s.add_dependency "rails"
end
