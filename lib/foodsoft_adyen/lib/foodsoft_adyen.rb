require 'adyen'
require 'foodsoft_adyen/engine'
require 'foodsoft_adyen/configuration'
require 'foodsoft_adyen/railtie'

module FoodsoftAdyen

  # return whether the current request is likely to support the mobile PIN app
  def self.detect_pin(request)
    true if self.get_mobile(request)
  end

  def self.encode_notification_data(data, title=nil)
    d = Base64.urlsafe_encode64 data.to_json
    return [title, "(#{d})"].compact.join(' ')
  end

  protected

  # return mobile platform of current request, if any
  def self.get_mobile(request)
    if not request or not request.user_agent
      nil
    elsif request.user_agent.match /\bAndroid\b/
      'Android'
    elsif request.user_agent.match /\b(iPod|iPhone|iPad)\b/
      'iOS'
    else
      nil
    end
  end

end
