class InvitesController < ApplicationController

  before_filter :authenticate_membership_or_admin_for_invites
  
  def new
    @invite = Invite.new(:user => @current_user, :group => @group)
  end
  
  def create
    authenticate_membership_or_admin params[:invite][:group_id]
    # admins may send invites to multiple email addresses at once
    emails = params[:invite][:email]
    emails = emails.split(/\s*(,|\s)\s*/).reject{|e| e.blank? or e==','} if @current_user.role_admin?
    emails.is_a? Array or emails = [emails]

    Invite.transaction do
      begin
        invites = emails.map do |email|
          invite = Invite.new(params[:invite].merge(email: email))
          invite.save!
          invite
        end
        # only send them when all invites were valid
        # TODO move sending to Resque queue
        invites.each do |invite|
          Mailer.invite(invite).deliver
        end

        respond_to do |format|
          format.html do
            redirect_to root_path, notice: I18n.t('invites.success', count: emails.count)
          end
          format.js { render layout: false }
        end

      rescue ActiveRecord::RecordInvalid => e
        flash[:error] = "#{e.message}: #{e.record.email}"
        @invite = Invite.new(params[:invite])
        render action: :new
      end
    end
  end

  protected

  def authenticate_membership_or_admin_for_invites
    authenticate_membership_or_admin((params[:invite][:group_id] rescue params[:id]))
  end
end
