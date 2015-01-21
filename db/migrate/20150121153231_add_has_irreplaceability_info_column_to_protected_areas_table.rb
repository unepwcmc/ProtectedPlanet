class AddHasIrreplaceabilityInfoColumnToProtectedAreasTable < ActiveRecord::Migration
  def change
    add_column :protected_areas, :has_irreplaceability_info, :boolean, default: false
  end
end
