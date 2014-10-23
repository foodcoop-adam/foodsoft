# stores the quantity, tolerance and timestamp of an GroupOrderArticle
# Considers every update of an article-order, so may rows for one group_order_article ar possible.

class GroupOrderArticleQuantity < ActiveRecord::Base

  belongs_to :group_order_article
  
  validates_presence_of :group_order_article_id
  validates_inclusion_of :quantity, :in => 0..99
  validates_inclusion_of :tolerance, :in => 0..99

end
