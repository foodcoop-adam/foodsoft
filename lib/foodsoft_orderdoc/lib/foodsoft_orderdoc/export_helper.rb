#
# Fill in a spreadsheet template with numbers from a datafile.
#
# This allows us to return suppliers spreadsheets that they have sent,
# filled in with a foodcoop order.
# During import, `srcdata` is stored in the article. Because an order may
# reference a past import, this information is stored in the article (or
# should this be order_article in foodsoft, perhaps?).
#
#
#    ExportHelper.export([
#      {result: 1, unit_quantity: 1, srcdata: {file: '20140217_Aanbod_week_8-9.xlsx', sheet: 0, row: 11, col: 5}},
#      {result: 6, unit_quantity: 3, srcdata: {file: '20140217_Aanbod_week_8-9.xlsx', sheet: 0, row: 27, col: 5}},
#    ])
#
require 'fileutils'

module FoodsoftOrderdoc::ExportHelper

  class OrderdocException < Exception; end

  # returns filename of source document, raises exception on error
  def self.check_export(article_data, search_path=[])
    normalize_data! article_data
    # we could give an error, but as this usually means there are articles removed from sharedlists,
    # ignore them - they aren't deliverable anymore anyway, and we'd rather have something as output
    article_data.reject! {|a| a[:srcdata].blank?}
    #if article_data.find_index {|a| a[:srcdata].blank?}
    #  raise OrderdocException.new(I18n.t('lib.foodsoft_orderdoc.error_no_srcdata'))
    #end
    fns = data_filenames(article_data)
    if fns.count == 0
      raise OrderdocException.new(I18n.t('lib.foodsoft_orderdoc.error_spreadsheet_none'))
    elsif fns.count > 1
      raise OrderdocException.new(I18n.t('lib.foodsoft_orderdoc.error_spreadsheet_multiple'))
    end

    src = find_file(fns[0], search_path) # TODO sanitize filename!
    raise OrderdocException.new(I18n.t('lib.foodsoft_orderdoc.error_spreadsheet_notfound')) if src.nil?
    return src
  end

  # return document with ordering data from a supplier's template
  def self.export(article_data, search_path=[])
    begin
      src = check_export article_data, search_path
    rescue OrderdocException => e
      return {error: e.message}
    end

    # XXX needs to have setup OpenOffice.org script
    # OpenOffice.org does not like to work on tempfiles, so create new files with same path
    dst = Tempfile.new(['orderdoc_cells_', src.gsub(/^.*\./, '.')]).to_path
    celldata = Tempfile.new(['orderdoc_cells_', '.dat']).to_path
    begin
      FileUtils.copy_file(src, dst, true)
      File.open(celldata, 'w+') do |f|
        article_data.each do |a|
          p = a[:srcdata] or next
          value = case p[:val]
                  when nil, 'result' then a[:result]
                  when 'quantity' then a[:unit_quantity].to_i * a[:result].to_f
                  else '?'
                  end
          f.puts "#{p[:sheet].to_i} #{p[:row].to_i} #{p[:col].to_i} #{value}" if value.present? and value != 0
        end
      end
      Rails.logger.debug "libreoffice --headless --nolockcheck 'macro:///Standard.Module1.UpdateCells(#{dst},#{celldata})' >/dev/null"
      %x(libreoffice --headless --nolockcheck 'macro:///Standard.Module1.UpdateCells(#{dst},#{celldata})' >/dev/null)
    ensure
      output = File.read(dst)
      File.delete dst
      File.delete celldata
    end

    # The sheets gem did not maintain spreadsheet formatting,
    # the workbook gem did not work at all, or complained about unsupported features in the source document,
    # and so I went for OpenOffice.org (which allows writing in many formats as well).

    {data: output, filename: File.basename(src), filetype: MimeMagic.by_path(src)}
  end

  private

  def self.normalize_data!(article_data)
    article_data.each do |a|
      a[:srcdata] = YAML.load(a[:srcdata]) if a[:srcdata].is_a? String
    end
  end

  def self.data_filenames(article_data)
    article_data.map{|a| a[:srcdata][:file]}.uniq.compact
  end

  def self.find_file(filename, search_path=[])
    return filename if File.exists? filename
    search_path.each do |path|
      f = File.join(path, filename)
      return f if File.exists? f
    end
    nil
  end

end
