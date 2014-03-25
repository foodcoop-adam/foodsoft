# A GroupOrder represents an Order placed by an Ordergroup.
class GroupOrder < ActiveRecord::Base

  attr_accessor :group_order_articles_attributes

  belongs_to :order
  belongs_to :ordergroup
  has_many :group_order_articles, :dependent => :destroy
  has_many :order_articles, :through => :group_order_articles
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by_user_id"

  validates_presence_of :order_id
  validates_presence_of :ordergroup_id
  validates_numericality_of :price, :gross_price, :net_price, :deposit
  validates_uniqueness_of :ordergroup_id, :scope => :order_id   # order groups can only order once per order

  # cannot use merge on joined scope - at least until after rails 3.2.13
  # https://github.com/rails/rails/issues/10303
  #scope :in_open_orders, joins(:order).merge(Order.open)
  #scope :in_finished_orders, joins(:order).merge(Order.finished_not_closed)
  scope :in_open_orders, joins(:order).where(:orders => {:state => 'open'})
  scope :in_finished_orders, joins(:order).where(:orders => {:state => 'finished'})

  scope :ordered, :include => :ordergroup, :order => 'groups.name'

  # Updates the "price" attribute.
  def update_price!
    goas = group_order_articles.includes(:order_article => [:article, :article_price])
    prices = goas.reduce({price: 0, gross_price: 0, net_price: 0, deposit: 0}) do |sum, goa|
      totals = goa.total_prices
      sum.keys.each {|s| sum[s] += totals[s] if totals[s]}
      sum
    end
    update_attributes prices
  end

end

