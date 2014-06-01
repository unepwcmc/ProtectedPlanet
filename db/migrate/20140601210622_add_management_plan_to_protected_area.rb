class AddManagementPlanToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :management_plan, :text
  end
end
