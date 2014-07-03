require 'net/http'
require 'uri'

module FoodsoftVokomokum

  class VokomokumException < Exception; end
  class AuthnException < VokomokumException; end
  class UploadException < VokomokumException; end

  # Validate user at Vokomokum member system from existing cookies, return user info.
  #   When an unexpected condition occurs, raises FoodsoftVokomokum::AuthnException.
  #   When the user was not logged in, returns `nil`.
  def self.check_user(cookies)
    res = members_req('userinfo', cookies)
    Rails.logger.debug 'Vokomokum check_user returned: ' + res.body
    json = ActiveSupport::JSON.decode(res.body)
    json['error'] and raise AuthnException.new('Vokomokum login failed: ' + json['error'])
    json['user_id'].blank? and return
    {
      id: json['user_id'],
      first_name: json['given_name'],
      last_name: [json['middle_name'], json['family_name']].compact.join(' '),
      email: json['email']
    }
  rescue ActiveSupport::JSON.parse_error => error
    raise AuthnException.new('Vokomokum login returned an invalid response: ' + error.message)
  end

  # Upload ordergroup totals to Vokomokum system.
  #   This is a hash of {ordergroup_id: sum}
  #   Type can be one of 'Groente', 'Kaas', 'Misc.'
  def self.upload_amounts(amounts, type)
    Rails.logger.debug "Vokomokum update for #{type}: #{amounts.inspect}"

    # first submit as CSV to see if there are any errors
    self.upload_amounts_csv(amounts, type)

    type = type.downcase.gsub '.',''
    parms = {submit: 'Submit', which: type, column: "mo_vers_#{type}"}

    amounts.each_pair do |ordergroup, amount|
      user = user_for_ordergroup(ordergroup)
      if user.nil?
        if 0 != amount
          Rails.logger.warn "Ordergroup ##{ordergroup} has no users, cannot book amount: #{amount}"
        end
      elsif user.id < 20000 # only upload amounts for vokomokum users
        parms["mo_vers_#{type}_#{user.id}"] = amount
      end
    end

    res = order_req('/cgi-bin/vers_upload.cgi', parms);
    if res.body =~ /<h2\s+class="errmsg"[^>]*>(.*?)<\/h2>/m
      raise UploadException.new("Vokomokum upload failed: #{$1}")
    end
  end

  # Submit amounts as CSV.
  # An UploadException is raised if there are any errors in the data.
  def self.upload_amounts_csv(amounts, type)
    # submit fresh page
    res = order_req('/cgi-bin/vers_upload.cgi', {
                      type => type,
                      paste: export_amounts(amounts)
    });
    if res.body =~ /<h2\s+class="errmsg"[^>]*>(.*?)<\/h2>/m
      raise UploadException.new("Vokomokum upload failed: #{$1}")
    end

    # TODO submit the form, or it won't be saved at all
  end



  protected

  def self.members_req(path, cookies)
    data = {client_id: FoodsoftConfig[:vokomokum_client_id], client_secret: FoodsoftConfig[:vokomokum_client_secret]}
    self.remote_req(FoodsoftConfig[:vokomokum_members_url], path, data, cookies)
  end

  def self.order_req(path, data)
    data = data.merge({client_id: FoodsoftConfig[:vokomokum_client_id], client_secret: FoodsoftConfig[:vokomokum_client_secret]})
    self.remote_req(FoodsoftConfig[:vokomokum_order_url], path, data)
  end

  def self.remote_req(url, path, data=nil, cookies={})
    # only keep relevant cookies
    cookies = cookies.select {|k,v| k=='Mem' || k=='Key'}
    uri = URI.join(url, path)
    if data.nil?
      req = Net::HTTP::Get.new(uri.request_uri)
    else
      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data data
    end
    # TODO cookie-encode the key and value
    req['Cookie'] = cookies.to_a.map {|v| "#{v[0]}=#{v[1]}"}.join('; ') #

    begin
      res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req) }
    rescue Timeout::Error => exc
      raise UploadException.new("Timeout while connecting to Vokomokum: #{exc.message}")
    rescue Errno::ETIMEDOUT => exc
      raise UploadException.new("Timeout while connecting to Vokomokum: #{exc.message}")
    rescue Errno::ECONNREFUSED => exc
      raise UploadException.new("Could not connect to Vokomokum: #{exc.message}")
    rescue Exception => exc
      raise UploadException.new("Could not connect to Vokomokum: #{exc.message}")
    end

    res.code.to_i == 200 or raise UploadException.new("Vokomokum upload returned with HTTP error #{res.code}")
    res
  end

end
