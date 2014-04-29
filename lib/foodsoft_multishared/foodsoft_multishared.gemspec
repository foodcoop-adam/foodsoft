$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_multishared/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_multishared"
  s.version     = FoodsoftMultishared::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoop-adam/foodsoft"
  s.summary     = "Foodsoft plugin for storing multiple foodcoops in a single database."
  s.description = "Allows multiple foodcoops to participate in each others' orders."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["README.md"]

  s.add_dependency 'rails'
  s.add_dependency 'deface', '~> 1.0'

  s.add_dependency 'gmaps4rails'
  s.add_dependency 'underscore-rails'
  s.add_dependency 'markerclustererplus-rails'
  s.add_dependency 'jquery-scrollto-rails'
end
