$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "foodsoft_split_manufacturer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "foodsoft_split_manufacturer"
  s.version     = FoodsoftSplitManufacturer::VERSION
  s.authors     = ["wvengen"]
  s.email       = ["dev-foodsoft@willem.engen.nl"]
  s.homepage    = "https://github.com/foodcoop-adam/foodsoft"
  s.summary     = "Allow operations orders by manufacturer on some places."
  s.description = nil

  s.files = Dir["{app,config,db,lib}/**/*"] + ["README.md"]

  s.add_dependency "rails"
  s.add_dependency "deface", "~> 1.0.0"
end
