
class UserinfoController < ApplicationController

  skip_before_filter :authenticate

  def userinfo
    data = {}
    if current_user
      data = {user_id: current_user.id,
              given_name: current_user.first_name,
              last_name: current_user.last_name,
              email: current_user.email,
              locale: I18n.locale}
      data[:nickname] = current_user.nick if FoodsoftConfig[:use_nick]
    else
      data = {error: 'access_denied'}
    end
    render :json => data.to_json
  end

end
