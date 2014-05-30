# encoding: utf-8
#
# Ordergroups can order, they are "children" of the class Group
# 
# Ordergroup have the following attributes, in addition to Group
# * account_balance (decimal)
class Ordergroup < Group

  APPLE_MONTH_AGO = 6                 # How many month back we will count tasks and orders sum

  serialize :stats

  has_many :financial_transactions
  has_many :group_orders
  has_many :orders, :through => :group_orders

  validates_numericality_of :account_balance, :message => I18n.t('ordergroups.model.invalid_balance')
  validate :uniqueness_of_name, :uniqueness_of_members

  after_create :update_stats!
  after_initialize :default_price_markup_key

  def contact
    "#{contact_phone} (#{contact_person})"
  end
  def non_members
    User.natural_order.all.reject { |u| (users.include?(u) || u.ordergroup) }
  end

  # the most recent order this ordergroup was participating in
  def last_order
    orders.order('orders.starts DESC').first
  end

  def value_of_open_orders(exclude = nil)
    group_orders.in_open_orders.reject{|go| go == exclude}.collect(&:price).sum
  end
  
  def value_of_finished_orders(exclude = nil)
    group_orders.in_finished_orders.reject{|go| go == exclude}.collect(&:price).sum
  end

  # Returns the available funds for this order group (the account_balance minus price of all non-closed GroupOrders of this group).
  # @param exclude [GroupOrder] Exclude this +GroupOrder+ from the calculation.
  def get_available_funds(exclude = nil)
    account_balance - value_of_open_orders(exclude) - value_of_finished_orders(exclude)
  end

  # Creates a new FinancialTransaction for this Ordergroup and updates the account_balance accordingly.
  # Throws an exception if it fails.
  def add_financial_transaction!(amount, note, user, options = {})
    FinancialTransaction.create! options.merge({ordergroup: self, amount: amount, note: note, user: user})
  end

  # Recomputes the account balance from financial transactions.
  # @param transaction [FinancialTransaction] Financial transaction that caused this change, or +nil+ to use the last updated one.
  # @param notify [Boolean] Set to +false+ to disable sending negative balance notifications.
  def update_balance!(transaction = nil, options = {})
    old_account_balance = self.account_balance
    self.account_balance = financial_transactions.sum('amount')
    save!
    # Notify only when order group had a positive balance
    if account_balance < 0 && old_account_balance >= 0
      transaction ||= financial_transactions.order(:updated_on).last
      Resque.enqueue(UserNotifier, FoodsoftConfig.scope, 'negative_balance', self.id, transaction.id) if (options[:notify]||true)
    end
    account_balance
  end

  # Recomputes job statistics from group orders.
  def update_stats!
    # Get hours for every job of each user in period
    jobs = users.sum { |u| u.tasks.done.sum(:duration, :conditions => ["updated_on > ?", APPLE_MONTH_AGO.month.ago]) }
    # Get group_order.price for every finished order in this period
    # cannot use merge on joined scope - at least until after rails 3.2.13
    #   https://github.com/rails/rails/issues/10303
    #   what's meant here is: where(:orders...) --> merge(Order.finished)
    orders_sum = group_orders.includes(:order).where(:orders=>{:state=>['finished','closed']}).where('orders.ends >= ?', APPLE_MONTH_AGO.month.ago).sum(:price)

    @readonly = false # Dirty hack, avoid getting RecordReadOnly exception when called in task after_save callback. A rails bug?
    update_attribute(:stats, {:jobs_size => jobs, :orders_sum => orders_sum})
  end

  def avg_jobs_per_euro
    stats[:jobs_size].to_f / stats[:orders_sum].to_f rescue 0
  end

  # This is the ordergroup job per euro performance in comparison to the whole foodcoop average.
  def apples
    ((avg_jobs_per_euro / Ordergroup.avg_jobs_per_euro) * 100).to_i rescue 0
  end

  # If the the option stop_ordering_under is set, the ordergroup is only allowed to participate in an order,
  # when the apples value is above the configured amount.
  # The restriction can be deactivated for each ordergroup.
  # Only ordergroups, which have participated in more than 5 orders in total and more than 2 orders in apple time period
  def not_enough_apples?
    FoodsoftConfig[:stop_ordering_under].present? and
        !ignore_apple_restriction and
        apples < FoodsoftConfig[:stop_ordering_under] and
        group_orders.count > 5 and
        group_orders.joins(:order).
        where(:orders=>{:state=>['finished','closed']}). # see comment in update_stats!
        where('orders.ends >= ?', APPLE_MONTH_AGO.month.ago).count > 2
  end

  # Global average
  def self.avg_jobs_per_euro
    stats = Ordergroup.pluck(:stats)
    stats.sum {|s| s[:jobs_size].to_f } / stats.sum {|s| s[:orders_sum].to_f } rescue 0
  end

  def account_updated
    financial_transactions.last.try(:updated_on) || created_on
  end

  def self.build_from_user(user, attributes = {})
    og = Ordergroup.new({:name => name_from_user(user)})
    og.contact_person = user.name unless user.name.blank?
    og.contact_phone = user.phone unless user.phone.blank?
    og.assign_attributes attributes
    # create membership (vs. setting user_ids) to allow new users to associate
    user.memberships << Membership.new(group: og)
    og
  end
  
  # return price markup percentage for this ordergroup
  def markup_pct
    if list = FoodsoftConfig[:price_markup_list]
      list[price_markup_key]['markup'].to_f
    else
      FoodsoftConfig[:price_markup].to_f
    end
  end

  private

  # Make sure, that a user can only be in one ordergroup
  def uniqueness_of_members
    users.each do |user|
      errors.add :user_tokens, I18n.t('ordergroups.model.error_single_group', :user => user.display) if user.groups.where(:type => 'Ordergroup').size > 1
    end
  end

  # Make sure, the name is uniq, add usefull message if uniq group is already deleted
  def uniqueness_of_name
    group = Ordergroup.where('groups.name = ?', name)
    group = group.where('groups.id != ?', self.id) unless new_record?
    if group.exists?
      message = group.first.deleted? ? :taken_with_deleted : :taken
      errors.add :name, message
    end
  end

  def default_price_markup_key
    # make sure there is a default value
    self.price_markup_key ||= FoodsoftConfig[:price_markup] if FoodsoftConfig[:price_markup_list]
  rescue ActiveModel::MissingAttributeError
    # this should only happen on Model.exists?() call. It can be safely ignored.
    # http://www.tatvartha.com/2011/03/activerecordmissingattributeerror-missing-attribute-a-bug-or-a-features/
  end

  # generate an unique ordergroup name from a user
  def self.name_from_user(user)
    name = user.display.truncate(25, omission: '').rstrip
    suffix = 2
    while Ordergroup.where(name: name).exists? do
      name = "#{user.display.truncate(20, omission: '').rstrip} (#{suffix})"
      suffix += 1
    end
    name
  end
 
end

