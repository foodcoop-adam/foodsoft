class AddUseToleranceToSupplier < ActiveRecord::Migration
  def change
    add_column :suppliers, :use_tolerance, :boolean, default: true
  end
end
