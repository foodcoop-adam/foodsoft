class AddFoodcoopToModels1 < ActiveRecord::Migration
  def change
    add_scope_to :groups
    add_scope_to :orders
    add_scope_to :suppliers
    add_scope_to :article_categories
    add_scope_to :invites
    add_scope_to :tasks

    # this is not yet complete, expect a future migration for:
    # article (needed for stock articles), delivery?, task (when without group), more?
  end

  def add_scope_to(table)
    add_column table, :scope, :string
    add_index table, :scope
    # set scope for current records to FoodsoftConfig.scope
    table.to_s.classify.constantize.update_all scope: FoodsoftConfig.scope
  end
end
