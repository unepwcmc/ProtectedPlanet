class AddLegalStatusUpdatedAtToProtectedArea < ActiveRecord::Migration
  def change
    add_column :protected_areas, :legal_status_updated_at, :datetime
  end
end
