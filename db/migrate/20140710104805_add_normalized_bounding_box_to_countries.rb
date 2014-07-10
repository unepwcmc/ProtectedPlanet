class AddNormalizedBoundingBoxToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :normalized_bounding_box, :geometry
  end
end
