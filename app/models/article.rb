# encoding: utf-8
class Article < ActiveRecord::Base

  # Replace numeric seperator with database format
  localize_input_of :price, :tax, :deposit
  # Get rid of unwanted whitespace. {Unit#new} may even bork on whitespace.
  normalize_attributes :name, :unit, :note, :manufacturer, :origin, :order_number, :fc_note

  # Associations
  belongs_to :supplier
  belongs_to :article_category
  has_many :article_prices, :order => "created_at DESC"
  has_many :order_articles

  scope :undeleted, -> { where(deleted_at: nil) }
  scope :available, -> { undeleted.where(availability: true) }
  scope :not_in_stock, :conditions => {:type => nil}

  # Validations
  validates_presence_of :name, :unit, :price, :tax, :deposit, :unit_quantity, :supplier_id, :article_category
  validates_length_of :name, :in => 4..60
  validates_length_of :unit, :in => 2..15
  validates_numericality_of :price, :greater_than_or_equal_to => 0
  validates_numericality_of :unit_quantity, :greater_than => 0
  validates_numericality_of :deposit, :tax
  #validates_uniqueness_of :name, :scope => [:supplier_id, :deleted_at, :type], if: Proc.new {|a| a.supplier.shared_sync_method.blank? or a.supplier.shared_sync_method == 'import' }
  #validates_uniqueness_of :name, :scope => [:supplier_id, :deleted_at, :type, :unit, :unit_quantity]
  validate :uniqueness_of_name
  
  # Callbacks
  before_save :update_price_history
  before_destroy :check_article_in_use

  def title
    "#{name} (#{unit})"
  end

  # combined note and foodcoop-note
  def full_note
    [fc_note, note].compact.join("; ")
  end

  def tax_price(group=nil)
    ArticlePrice.tax_price(self, group)
  end
  
  # The financial gross, net plus tax and deposti
  def gross_price(group=nil)
    ArticlePrice.gross_price(self, group)
  end

  # The price part which is tax (excl. any tax on markup)
  def tax_price(group=nil)
    ArticlePrice.tax_price(self, group)
  end

  # The price for the foodcoop-member.
  def fc_price(group=nil)
    ArticlePrice.fc_price(self, group)
  end

  # The amount of tax in the price for the foodcoop-member (incl. any taxes over the markup).
  def fc_tax_price(group=nil)
    ArticlePrice.fc_tax_price(self, group)
  end

  # The amount of tax in the price for the foodcoop-member (incl. any taxes over the markup).
  def fc_markup_price(group=nil)
    ArticlePrice.fc_markup_price(self, group)
  end

  # @return [Unit] Unit class for article unit, or +nil+ when unparsable.
  # @todo check caching this value during a request doesn't give problems
  def unit_unit
    @unit_unit ||= (::Unit.new(self[:unit]) rescue nil)
  end
  
  # Returns true if article has been updated at least 2 days ago
  def recently_updated
    updated_at > 2.days.ago
  end
  
  # If the article is used in an open Order, the Order will be returned.
  def in_open_order
    @in_open_order ||= begin
      order_articles = OrderArticle.all(:conditions => ['order_id IN (?)', Order.open.collect(&:id)])
      order_article = order_articles.detect {|oa| oa.article_id == id }
      order_article ? order_article.order : nil
    end
  end
  
  # Returns true if the article has been ordered in the given order at least once
  def ordered_in_order?(order)
    order.order_articles.where(article_id: id).where('quantity > 0').one?
  end
  
  # this method checks, if the shared_article has been changed
  # unequal attributes will returned in array
  # if only the timestamps differ and the attributes are equal, 
  # false will returned and self.shared_updated_on will be updated
  def shared_article_changed?(supplier = self.supplier)
    # skip early if the timestamp hasn't changed
    shared_article = self.shared_article(supplier)
    unless shared_article.nil? or self.shared_updated_on == shared_article.updated_on
      
      # try to convert units
      # convert supplier's price and unit_quantity into fc-size
      new_price, new_unit_quantity = self.convert_units
      new_unit = self.unit
      unless new_price and new_unit_quantity
        # if convertion isn't possible, take shared_article-price/unit_quantity
        new_price, new_unit_quantity, new_unit = shared_article.price, shared_article.unit_quantity, shared_article.unit
      end
      
      # check if all attributes differ
      unequal_attributes = Article.compare_attributes(
        {
          :name => [self.name, shared_article.name],
          :manufacturer => [self.manufacturer, shared_article.manufacturer.to_s],
          :origin => [self.origin, shared_article.origin],
          :unit => [self.unit, new_unit],
          :price => [self.price.to_f.round(2), new_price.to_f.round(2)],
          :tax => [self.tax, shared_article.tax],
          :deposit => [self.deposit.to_f.round(2), shared_article.deposit.to_f.round(2)],
          # take care of different num-objects.
          :unit_quantity => [self.unit_quantity.to_s.to_f.round(1), new_unit_quantity.to_s.to_f.round(1)],
          :quantity => [self.quantity, shared_article.quantity],
          :note => [self.note.to_s, shared_article.note.to_s]
        }
      )
      if unequal_attributes.empty?            
        # when attributes not changed, update timestamp of article
        self.update_attribute(:shared_updated_on, shared_article.updated_on)
        false
      else
        unequal_attributes
      end
    end
  end
  
  # compare attributes from different articles. used for auto-synchronization
  # returns array of symbolized unequal attributes
  def self.compare_attributes(attributes)
    unequal_attributes = attributes.select { |name, values| values[0] != values[1] and not (values[0].blank? and values[1].blank?) }
    unequal_attributes.collect { |pair| pair[0] }
  end
  
  # to get the correspondent shared article
  def shared_article(supplier = self.supplier)
    self.order_number.blank? and return nil
    @shared_article ||= supplier.shared_supplier.shared_articles.find_by_number(self.order_number) rescue nil
  end
  
  # convert units in foodcoop-size
  # uses unit factors in app_config.yml to calc the price/unit_quantity
  # returns new price and unit_quantity in array, when calc is possible => [price, unit_quanity]
  # returns false if units aren't foodsoft-compatible
  # returns nil if units are eqal
  def convert_units
    if unit != shared_article.unit
      # legacy, used by foodcoops in Germany
      if shared_article.unit == "KI" and unit == "ST" # 'KI' means a box, with a different amount of items in it
        # try to match the size out of its name, e.g. "banana 10-12 St" => 10
        # unit_quantity would be an integer, but to show when it's not whole, return float instead
        new_unit_quantity = /[0-9\-\s]+(St)/.match(shared_article.name).to_f.round(1)
        if new_unit_quantity and new_unit_quantity > 0
          new_price = (shared_article.price/new_unit_quantity.to_f).round(3)
          [new_price, new_unit_quantity]
        else
          false
        end
      else # use ruby-units to convert
        fc_unit = (::Unit.new(unit) rescue nil)
        supplier_unit = (::Unit.new(shared_article.unit) rescue nil)
        if fc_unit and supplier_unit and fc_unit =~ supplier_unit
          conversion_factor = (fc_unit.convert_to(supplier_unit.units) / supplier_unit).scalar
          new_price = (shared_article.price * conversion_factor).to_f.round(3)
          new_unit_quantity = (shared_article.unit_quantity / conversion_factor).to_f.round(1)
          [new_price, new_unit_quantity]
        else
          false
        end
      end
    else
      nil
    end
  end

  def deleted?
    deleted_at.present?
  end

  def mark_as_deleted
    check_article_in_use
    update_column :deleted_at, Time.now
  end

  # product information url, fallback to optional supplier-wide value
  def info_url(supplier=self.supplier)
    self[:info_url] or supplier.article_info_url(self)
  end

  def use_tolerance?
    supplier.use_tolerance? and unit_quantity > 1
  end

  protected
  
  # Checks if the article is in use before it will deleted
  def check_article_in_use
    raise I18n.t('articles.model.error_in_use', :article => self.name.to_s) if self.in_open_order
  end

  # Create an ArticlePrice, when the price-attr are changed.
  def update_price_history
    if price_changed?
      article_prices.build(
        :price => price,
        :tax => tax,
        :deposit => deposit,
        :unit_quantity => unit_quantity
      )
    end
  end

  def price_changed?
    changed.detect { |attr| attr == 'price' || 'tax' || 'deposit' || 'unit_quantity' } ? true : false
  end

  # We used have the name unique per supplier+deleted_at+type. With the addition of shared_sync_method all,
  # this came in the way, and we now allow duplicate names for the 'all' methods - expecting foodcoops to
  # make their own choice among products with different units by making articles available/unavailable.
  def uniqueness_of_name
    matches = Article.where(name: name, supplier_id: supplier_id, deleted_at: deleted_at, type: type)
    matches = matches.where('id != ?', id) unless new_record?
    if supplier.shared_sync_method.blank? or supplier.shared_sync_method == 'import'
      errors.add :name, :taken if matches.any?
    else
      errors.add :name, :taken_with_unit if matches.where(unit: unit, unit_quantity: unit_quantity).any?
    end
  end

end
