require 'uri'

module VokomokumHelper
  def remote_vokomokum_login_url(user=@current_user)
    URI.join(FoodsoftConfig[:vokomokum_members_url], 'member/', "#{user.id.to_s}/", 'edit').to_s
  end
end
