$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_mailall/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_mailall"
  s.version     = FoodsoftMailall::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoop-adam/foodsoft"
  s.summary     = "Plugin for foodsoft adding a 'mail all' button."
  s.description = "Adds a button to the users admin page to mail or export all users."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["README.md"]

  s.add_dependency "rails"
  s.add_dependency "content_for_in_controllers"
end
