require 'net/http'
require 'uri'

module FoodsoftVokomokum

  class VokomokumException < Exception; end
  class AuthnException < VokomokumException; end
  class InactiveException < AuthnException; end
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
    json['active'] or raise InactiveException.new("Welcome back! You can't order just yet, please contact membership@vokomokum.nl to become active again.")
    {
      id: json['user_id'],
      first_name: json['given_name'],
      last_name: [json['middle_name'], json['family_name']].compact.join(' '),
      email: json['email'],
      groups: json['groups']
    }
  rescue ActiveSupport::JSON.parse_error => error
    raise AuthnException.new('Vokomokum login returned an invalid response: ' + error.message)
  end

  # Charges members
  # @return [String] Status message on success
  def self.charge_members!(cookies, charges)
    res = members_req('charge-members', cookies, {charges: charges})
    Rails.logger.debug 'Vokomokum charge-members returned: ' + res.body
    json = ActiveSupport::JSON.decode(res.body)
    if json['status'] == 'ok'
      json['msg']
    elsif json['msg'] =~ /only .* people can do this/i
      raise AuthnException.new('Vokomokum charge-members failed: ' + json['msg'])
    else
      raise VokomokumException.new('Vokomokum charge-members failed: ' + json['msg'])
    end
  end

  protected

  def self.members_req(path, cookies, data={})
    data = {client_id: FoodsoftConfig[:vokomokum_client_id], client_secret: FoodsoftConfig[:vokomokum_client_secret]}.merge(data)
    self.remote_req(FoodsoftConfig[:vokomokum_members_url], path, data, cookies)
  end

  def self.remote_req(url, path, data=nil, cookies={})
    # only keep relevant cookies
    cookies = cookies.select {|k,v| k=='Mem' || k=='Key'}
    uri = URI.join(url, path)
    if data.nil?
      req = Net::HTTP::Get.new(uri.request_uri)
    else
      req = Net::HTTP::Post.new(uri.request_uri)
      req.content_type = 'application/json'
      req.body = data.to_json
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

    res.code.to_i == 200 or raise UploadException.new("Vokomokum request returned with HTTP error #{res.code}")
    res
  end

end
