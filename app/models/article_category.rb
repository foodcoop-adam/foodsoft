class ArticleCategory < ActiveRecord::Base
  has_many :articles

  has_ancestry
  acts_as_list scope: [:ancestry]
  include TheSortableTree::Scopes

  default_scope -> { order('position') }

  normalize_attributes :name, :description

  validates :name, :presence => true, :uniqueness => true, :length => { :minimum => 2 }

  before_destroy :check_for_associated_articles

  # Find a category that matches a category name; may return nil.
  # TODO more intelligence like remembering earlier associations (global and/or per-supplier)
  def self.find_match(category)
    return if category.blank? or category.length < 3
    c = nil
    ## exact match - not needed, will be returned by next query as well
    #c ||= ArticleCategory.where(name: category).first
    # case-insensitive substring match (take the closest match = shortest)
    c = ArticleCategory.where('name LIKE ?', "%#{category}%") unless c and c.any?
    # case-insensitive phrase present in category description
    c = ArticleCategory.where('description LIKE ?', "%#{category}%").select {|s| s.description.match /(^|,)\s*#{category}\s*(,|$)/i} unless c and c.any?
    # return closest match if there are multiple
    c = c.sort_by {|s| s.name.length}.first if c.respond_to? :sort_by
    c
  end

  protected

  def check_for_associated_articles
    raise I18n.t('activerecord.errors.has_many_left', collection: Article.model_name.human) if articles.undeleted.exists?
  end

end

