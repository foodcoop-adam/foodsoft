$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_adyen/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_adyen"
  s.version     = FoodsoftAdyen::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoop-adam/foodsoft"
  s.summary     = "Adyen payment plugin for foodsoft."
  s.description = "Integration with Adyen's payment solution. Supports notifications, PIN payments via the mobile app and hosted payment pages."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency "adyen"
  s.add_dependency "jquery_mobile_rails"
end
