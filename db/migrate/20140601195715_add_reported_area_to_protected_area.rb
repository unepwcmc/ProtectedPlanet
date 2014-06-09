class AddReportedAreaToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :reported_area, :decimal
  end
end
