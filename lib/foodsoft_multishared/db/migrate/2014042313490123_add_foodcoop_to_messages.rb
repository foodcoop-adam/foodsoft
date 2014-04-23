class AddFoodcoopToMessages < ActiveRecord::Migration
  def up
    if table_exists? :messages
      add_column :messages, :scope, :string
      add_index :messages, :scope
    end
    Message.update_all scope: FoodsoftConfig.scope if defined? FoodsoftMessages
  end

  def down
    if table_exists? :messages
      remove_column :messages, :scope
      remove_index :messages, :scope
    end
  end
end
