class AddBboxToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :bounding_box, :geometry
  end
end
