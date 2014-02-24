$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_payorder/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_payorder"
  s.version     = FoodsoftPayorder::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoop-adam/foodsoft"
  s.summary     = "Allows members to pay online right after ordering."
  s.description = "Allows members to pay online right after ordering."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["README.md"]

  s.add_dependency "rails"
  s.add_dependency "deface", "~> 1.0.0"
end
