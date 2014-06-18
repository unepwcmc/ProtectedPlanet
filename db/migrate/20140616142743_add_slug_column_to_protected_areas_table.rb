class AddSlugColumnToProtectedAreasTable < ActiveRecord::Migration
  def change
    add_column :protected_areas, :slug, :text
  end
end
