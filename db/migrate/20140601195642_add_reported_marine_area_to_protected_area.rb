class AddReportedMarineAreaToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :report_marine_area, :decimal
  end
end
