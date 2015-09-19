require 'uri'

module VokomokumHelper
  def remote_vokomokum_user_edit_url(user=@current_user)
    URI.join(FoodsoftConfig[:vokomokum_members_url], 'member/', "#{user.id.to_s}/", 'edit').to_s
  end

  def remote_vokomokum_user_url(user=@current_user)
    URI.join(FoodsoftConfig[:vokomokum_members_url], 'member/', "#{user.id.to_s}").to_s
  end

  # Override ordergroup path with one to the members system
  def my_ordergroup_path
    "#{remote_vokomokum_user_url}#transactions"
  end
end
