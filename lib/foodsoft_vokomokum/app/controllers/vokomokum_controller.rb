# encoding: utf-8
class VokomokumController < ApplicationController

  skip_before_filter :authenticate, :only => :login
  before_filter :authenticate_finance, :only => :export_amounts

  # Workgroup ids not managed by Vokomokum. On login each member's groups are
  # synchronised with Vokomokum. We assume that the first group is the admin group
  # and managed locally in Foodsoft.
  # @todo Add boolean to workgroup to indicate whether it is synchronized or not.
  FOODSOFT_WORKGROUP_IDS = [1]

  def login
    # use cookies, but allow to get them from parameters (if on other domain)
    sweets = params.slice(:Mem, :Key)
    sweets = {Mem: cookies[:Mem], Key: cookies[:Key]} if sweets.empty?

    userinfo = FoodsoftVokomokum.check_user(sweets)
    userinfo.nil? and raise FoodsoftVokomokum::AuthnException.new('User not logged in')
    user = update_or_create_user(userinfo[:id],
                                 userinfo[:email],
                                 userinfo[:first_name],
                                 userinfo[:last_name],
                                 find_workgroups(userinfo[:groups]))
    super user

    # store in session because we may need it later communicating to Vokomokum
    session[:vokomokum_auth_cookies] = sweets

    # XXX redirection code copied from SessionController#create
    if session[:return_to].present?
      redirect_to_url = session[:return_to]
      session[:return_to] = nil
    else
      redirect_to_url = root_url
    end
    redirect_to redirect_to_url

  rescue FoodsoftVokomokum::InactiveException => e
    Rails.logger.debug "Vokomokum authentication returned inactive user"
    redirect_with_params FoodsoftConfig[:vokomokum_members_url], error: 'user inactive'

  rescue FoodsoftVokomokum::AuthnException => e
    Rails.logger.warn "Vokomokum authentication failed: #{e.message}"
    redirect_with_params FoodsoftConfig[:vokomokum_members_url], came_from: request.original_url
  end

  def export_amounts
    send_data FoodsoftVokomokum.export_amounts, filename: 'vers.csv', type: 'text/plain; charset=utf-8', disposition: 'inline'
  end


  protected

  def update_or_create_user(id, email, first_name, last_name, workgroups=nil)
    User.transaction do
      begin
        user = User.find(id)
      rescue ActiveRecord::RecordNotFound
        user = User.new
        user.id = id
        # no password is used, enter complex random string
        user.password = user.new_random_password(8)
      end
      user.update_attributes email: email, first_name: first_name, last_name: last_name
      user.save!
      # make sure user has an ordergroup (different group id though, since we also have workgroups)
      unless user.ordergroup
        ordergroup = Ordergroup.create!(name: "#{'%03d'%id} #{user.display}".truncate(25, omission: "\u2026"))
        user.memberships.create!(group: ordergroup)
      end
      # update workgroups
      unless workgroups.nil?
        new_workgroups = workgroups + user.workgroups.where(id: FOODSOFT_WORKGROUP_IDS).to_a
        user.update_attributes workgroups: new_workgroups
      end
      user
    end
  end

  # Find Foodsoft groups for those returned from Vokomokum's userinfo endpoint.
  #
  # Looks at each group as returned from the userinfo endpoint, and returns Foodsoft
  # groups that this user belongs to.
  #
  # @param group_data [Aray<Hash<String, Object>>] Array of groups
  # @return [Array<Workgroup>] Foodsoft workgroups this user belongs to
  def find_workgroups(group_data)
    Workgroup.undeleted.where(name: group_data.map {|d| d['name']})
  end

  def redirect_with_params(url, params)
    returl = Addressable::URI.parse(url)
    returl.query_values = (returl.query_values or {}).merge(params)
    redirect_to returl.to_s
  end

end
