class AddIsoToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :iso, :string
  end
end
