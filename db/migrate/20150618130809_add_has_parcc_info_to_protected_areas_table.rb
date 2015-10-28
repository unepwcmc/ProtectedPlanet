class AddHasParccInfoToProtectedAreasTable < ActiveRecord::Migration
  def change
    add_column :protected_areas, :has_parcc_info, :boolean, default: false
  end
end
