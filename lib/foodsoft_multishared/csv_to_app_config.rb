#!/usr/bin/env ruby
#
# Generate Foodsoft app_config.yml configuration file (portion)
# for multishared groups from CSV.
#

require 'csv'

CSV.parse(File.read(ARGV[0], {headers: false})) do |row|
  name = row[1]
  email = row[2]
  city = row[3]
  zip = row[4].upcase.gsub(/\s+/, '')
  street = row[5]
  lat, lng = row[6], row[7]
  day = row[8].gsub(/\*/, '').gsub(/avond$/,'').downcase
  time = [row[9], row[10]]
  max = row[11]

  fcid = city.downcase.gsub(/\s+/, '-') + '-' + zip.gsub(/[^0-9]/, '')
  puts <<EOF
# #{name}
#{fcid}:
  <<: *defaults
  contact:
    street: #{street}
    zip_code: #{zip}
    city: #{city}
    country: Nederland
    email: #{email}
    lat: #{lat}
    lon: #{lng}
  list_desc: ophalen #{day} #{time.join('-')}
  signup_ordergroup_limit: #{max}

EOF
end
