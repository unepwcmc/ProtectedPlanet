class AddGovernanceIdToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :governance_id, :integer
  end
end
