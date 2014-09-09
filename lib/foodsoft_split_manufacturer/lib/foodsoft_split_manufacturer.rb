require "foodsoft_split_manufacturer/engine"
require "foodsoft_split_manufacturer/add_filter_to_pdfs"
require "foodsoft_split_manufacturer/add_manufacturer_to_pdf_controllers"

module FoodsoftSplitManufacturer
  def self.enabled?
    FoodsoftConfig[:use_split_manufacturer]
  end
end
