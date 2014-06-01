class AddManagementAuthorityIdToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :management_authority_id, :integer
  end
end
