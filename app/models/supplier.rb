# encoding: utf-8
class Supplier < ActiveRecord::Base

  has_many :articles, :conditions => {:type => nil},
    :include => [:article_category], :order => 'article_categories.name, articles.name'
  has_many :stock_articles, :include => [:article_category], :order => 'article_categories.name, articles.name'
  has_many :orders
  has_many :deliveries
  has_many :invoices
  belongs_to :shared_supplier  # for the sharedLists-App

  attr_accessible :name, :address, :phone, :phone2, :fax, :email, :url, :contact_person, :customer_number,
                  :delivery_days, :order_howto, :note, :shared_supplier_id, :min_order_quantity,
                  :article_info_url

  validates :name, :presence => true, :length => { :in => 4..30 }
  validates :phone, :presence => true, :length => { :in => 8..25 }
  validates :address, :presence => true, :length => { :in => 8..50 }
  validates_length_of :order_howto, :note, maximum: 250
  validate :uniqueness_of_name
  validate :valid_article_info_url_substitition

  scope :undeleted, -> { where(deleted_at: nil) }

  # sync all articles with the external database
  # returns an array with articles(and prices), which should be updated (to use in a form)
  # also returns an array with outlisted_articles, which should be deleted
  def sync_all
    updated_articles = Array.new
    outlisted_articles = Array.new
    for article in articles.undeleted
      # try to find the associated shared_article
      shared_article = article.shared_article

      if shared_article # article will be updated
        
        unequal_attributes = article.shared_article_changed?
        unless unequal_attributes.blank? # skip if shared_article has not been changed
          
          # try to convert different units
          new_price, new_unit_quantity = article.convert_units
          if new_price and new_unit_quantity
            article.price = new_price
            article.unit_quantity = new_unit_quantity
          else
            article.price = shared_article.price
            article.unit_quantity = shared_article.unit_quantity
            article.unit = shared_article.unit
          end
          # update other attributes
          article.attributes = {
            :name => shared_article.name,
            :manufacturer => shared_article.manufacturer,
            :origin => shared_article.origin,
            :shared_updated_on => shared_article.updated_on,
            :tax => shared_article.tax,
            :deposit => shared_article.deposit,
            :note => shared_article.note
          }
          updated_articles << [article, unequal_attributes]
        end
      # Articles with no order number can be used to put non-shared articles
      # in a shared supplier, with sync keeping them.
      elsif not article.order_number.blank?
        # article isn't in external database anymore
        outlisted_articles << article
      end
    end
    return [updated_articles, outlisted_articles]
  end

  def deleted?
    deleted_at.present?
  end

  def mark_as_deleted
    transaction do
      update_column :deleted_at, Time.now
      articles.each(&:mark_as_deleted)
    end
  end

  # return article info url for article, or the template if article not supplied
  # use %{column} substitution for article fields in url template
  def article_info_url(article=nil)
    self[:article_info_url].nil? and return nil
    self[:article_info_url].blank? and return nil
    article.nil? and return self[:article_info_url]
    self[:article_info_url].gsub /%{.*?}/ do |n|
      n = n[2..-2]
      nil unless n.in? Article.column_names
      article[n]
    end
  end

  # email address for sending an order to the supplier
  # put an email address in order_howto, and this will be returned
  def order_send_email
    if order_howto.try {|h| h.match /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i}
      order_howto
    end
  end

  protected

  # Make sure, the name is uniq, add usefull message if uniq group is already deleted
  def uniqueness_of_name
    supplier = Supplier.where('suppliers.name = ?', name)
    supplier = supplier.where('suppliers.id != ?', self.id) unless new_record?
    if supplier.exists?
      message = supplier.first.deleted? ? :taken_with_deleted : :taken
      errors.add :name, message
    end
  end

  # Make sure article_info_url substitutions are valid
  def valid_article_info_url_substitition
    self[:article_info_url].nil? and return
    self[:article_info_url].scan /%{(.*?)}/ do |n|
      n = n[0]
      unless n.in? Article.column_names
        errors.add :article_info_url, I18n.t('supplier.controller.errors.substitition')
      end
    end
  end
end

