class AddGovernanceIdIndexToProtectedArea < ActiveRecord::Migration
  def change
    add_index :protected_areas, :governance_id
  end
end
