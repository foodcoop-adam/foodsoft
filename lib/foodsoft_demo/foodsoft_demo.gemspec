$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_demo/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_demo"
  s.version     = FoodsoftDemo::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoops/foodsoft"
  s.summary     = "Demo plugin for foodsoft."
  s.description = "Adds features that aid in giving foodsoft demonstrations."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["README.md"]

  s.add_dependency "rails"
end
