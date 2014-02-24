class Admin::MailallController < Admin::BaseController

  def show
    require 'csv'
    @users = select_users(:all)
    fields = [:id, :name, :email, :phone, :ordergroup]
    fields << :approved if defined? FoodsoftSignup
    out = CSV.generate do |csv|
      csv << fields.map {|f| User.human_attribute_name f}
      @users.all.each do |user|
        csv << fields.map do |f|
          case f
          when :approved then user.ordergroup and user.ordergroup.approved?
          when :ordergroup then user.ordergroup and user.ordergroup.name
          else user.send f
          end
        end
      end
    end
    send_data out, filename: 'users.csv', type: 'text/csv'
  end

  def expand
    @users = {}
    @users[:all] = select_users :all
    @users[:current] = select_users :current
    @users[:approved] = select_users :approved if defined? FoodsoftSignup
    @users[:unapproved] = select_users :unapproved if defined? FoodsoftSignup
    @users[:csv] = true

    unless params[:type].blank?
      keep = params[:type].split(',').map(&:to_sym)
      @users.select! {|k,v| keep.index(k)}
    end

    @mailto = {}
    @users.each do |k,v|
      @mailto[k] = mail_link v if v.respond_to?(:where)
    end

    render layout: false
  end


  protected

  def select_users(type)
    case type
    when :all        then User
    when :current    then Ordergroup.joins(:orders).where(orders: {state: 'finished'}).joins(:users).select(:email).uniq
    when :approved   then User.joins(:groups).where(groups: {type: 'Ordergroup', approved: true}) if defined? FoodsoftSignup
    when :unapproved then User.joins(:groups).where(groups: {type: 'Ordergroup', approved: false}) if defined? FoodsoftSignup
    end
  end

  def mail_link(users)
    addr = users.pluck(:email).uniq.map{|s| "<#{s}>"}.join(', ')
    mail_path(nil, bcc: addr)
  end

  def mail_path(email_address, options)
    # some lines copied from actionpack/lib/action_view/helpers/url_helper.rb
    extras = options.to_a.map { |i|
      "#{i[0]}=#{Rack::Utils.escape_path(i[1])}"
    }.compact
    extras = extras.empty? ? '' : '?' + ERB::Util.html_escape(extras.join('&'))
    return "mailto:#{email_address}#{extras}".html_safe
  end

end
