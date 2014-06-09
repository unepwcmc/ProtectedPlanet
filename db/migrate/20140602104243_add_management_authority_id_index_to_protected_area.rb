class AddManagementAuthorityIdIndexToProtectedArea < ActiveRecord::Migration
  def change
    add_index :protected_areas, :management_authority_id
  end
end
