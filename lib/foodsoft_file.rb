# Module for FoodSoft-File import
# The FoodSoft-File is a cvs-file, with semicolon-seperatet columns

require 'csv'

module FoodsoftFile

  class ConversionFailedException < Exception;
    def message; "Conversion failed"; end
  end
  class ConversionDisabledException < Exception;
    def message; "Conversion disabled"; end
  end
  
  # parses a string from a foodsoft-file
  # returns two arrays with articles and outlisted_articles
  # the parsed article is a simple hash
  def self.parse(file, opts={})
    articles, outlisted_articles = Array.new, Array.new
    row_index = 2
    data = read_file file, opts
    col_sep = csv_guess_col_sep data
    ::CSV.parse(data, {:col_sep => col_sep, :headers => true}) do |row|
      # check if the line is empty
      unless row[2] == "" || row[2].nil?        
        article = {:number => row[1],
                   :name => row[2],
                   :note => row[3],
                   :manufacturer => row[4],
                   :origin => row[5],
                   :unit => row[6],
                   :price => row[7],
                   :tax => row[8],
                   :deposit => (row[9].nil? ? "0" : row[9]),
                   :unit_quantity => row[10],
                   :quantity => row[11],
                   :category => row[13]}
        case row[0]
        when "x"
          # check if the article is outlisted
          outlisted_articles << article
        else
          articles << article
        end
      end
      row_index += 1
    end
    return [articles, outlisted_articles]
  end

  private

  # TODO create separate gem / subtree shared with sharedlists

  # return most probable column separator character from first line
  def self.csv_guess_col_sep(file_or_data)
    seps = [",", ";", "\t", "|"]
    if file_or_data.is_a? File
      position = file_or_data.tell
      firstline = file_or_data.readline
      file_or_data.seek(position)
      what = file.path
    else
      firstline = file_or_data.split("\n").first
      what = "(inline data)"
    end
    sep = seps.map {|x| [firstline.count(x),x]}.sort_by {|x| -x[0]}[0][1]
    Rails.logger.debug "Guessed CSV separator '#{sep}' for #{what}"
    sep
  end

  def self.read_file(file, opts={})
    file = ensure_file_format file, opts
    data = file.read
    if defined? CharlockHolmes and opts[:encoding]
      data = CharlockHolmes::Converter.convert data, opts[:encoding], 'UTF-8'
    end
    data
  end

  # make sure we have a csv for a spreadsheet, and that it's a File
  def self.ensure_file_format(file, opts={})
    # catch original filename from uploaded files (see `Http::UploadedFile`)
    if file.respond_to?(:tempfile)
      filename = file.original_filename
      file = file.tempfile
    else
      filename = file.path
    end
    # convert spreadsheets
    if filename.match /\.(xls|xlsx|ods|sxc)$/i
      FoodsoftConfig[:use_libreoffice] or raise ConversionDisabledException
      Rails.logger.debug "Converting spreadsheet to CSV: #{file.path}"
      # for a temporary file, we want to have a temporary file back
      if file.kind_of?(Tempfile)
        file = convert_to_csv_temp(file)
      else
        filecsv = libreoffice_convert(file.path)
        file = File.new(filecsv)
        opts[:filename] ||= filename # store original filename
      end
    end
    # set encoding once
    if opts[:encoding].blank? or opts[:encoding].to_s == 'auto'
      if defined? CharlockHolmes
        encdet = CharlockHolmes::EncodingDetector.detect(file.read(4096*8))
        opts[:encoding] = encdet[:encoding] if encdet[:confidence] > 0.6
        Rails.logger.debug "Detected encoding '#{opts[:encoding]}' using CharlockHolmes"
      elsif defined? CharDet
        # CharDet didn't detect OpenOffice.org CSV export encoding properly
        encdet = CharDet.detect(file.read(4096*8))
        opts[:encoding] = encdet.encoding if encdet.confidence > 0.6
        Rails.logger.debug "Detected encoding '#{opts[:encoding]}' using CharDet"
      end
      file.rewind
    end
    file
  end

  # create a temporary csv for a spreadsheet
  def self.convert_to_csv_temp(file)
    FoodsoftConfig[:use_libreoffice] or raise ConversionDisabledException
    # first store in temporary directory because libreoffice doesn't allow to specify a filename
    Dir.mktmpdir do |tmpdir|
      filecsv = libreoffice_convert file.path, tmpdir
      filebase = File.basename(file).gsub(/\.\w+$/, '')
      # then move csv to temporary file that can be passed around
      file = Tempfile.new(["#{filebase}.", '.csv'])
      File.open(file, 'wb') do |dst|
        File.open(filecsv, 'rb') do |src|
          dst.write src.read(4096) while not src.eof
        end
      end
      file
    end
  end

  def self.libreoffice_convert(src, dstdir = File.dirname(src))
    FoodsoftConfig[:use_libreoffice] or raise ConversionDisabledException
    Rails.logger.debug "Running: libreoffice --headless --nolockcheck --convert-to csv '#{src}' --outdir '#{dstdir}' >/dev/null"
    %x(libreoffice --headless --nolockcheck --convert-to csv '#{src}' --outdir '#{dstdir}' >/dev/null)
    filecsv = File.join(dstdir, File.basename(src).gsub(/\.\w+$/, '')+'.csv')
    File.exist?(filecsv) or raise ConversionFailedException
    File.chmod(0600, filecsv) # TODO proper use of umask(!)
    filecsv
  end

end
