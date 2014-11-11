class AddFoodcoopNoteToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :fc_note, :string
  end
end
