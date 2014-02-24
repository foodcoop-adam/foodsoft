require 'net/http'
require 'uri'

module FoodsoftVokomokum

  class AuthnException < Exception; end

  # Validate user at Vokomokum member system from existing cookies, return user info
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

  # upload ordergroup totals to vokomokum system
  #   type can be one of 'Groente', 'Kaas', 'Misc.'
  def self.upload_amounts(amounts, type, cookies)
    # submit fresh page
    res = order_req('/cgi-bin/vers_upload.cgi', {
                      submit: type,
                      paste: export_amounts(data)
    }, cookies);
    # TODO check response
  end


  protected

  def self.members_req(path, cookies)
    data = {client_id: FoodsoftConfig[:vokomokum_client_id], client_secret: FoodsoftConfig[:vokomokum_client_secret]}
    self.remote_req(FoodsoftConfig[:vokomokum_members_url], path, data, cookies)
  end

  def self.order_req(path, data, cookies)
    self.remote_req(FoodsoftConfig[:vokomokum_order_url], path, data, cookies)
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
    res = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req) }
    res.code.to_i == 200 or raise AuthnException.new("Could not access Vokomokum, status #{res.code}")
    res
  end

end
