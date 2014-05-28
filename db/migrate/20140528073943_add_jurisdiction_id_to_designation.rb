class AddJurisdictionIdToDesignation < ActiveRecord::Migration
  def change
    add_column :designations, :jurisdiction_id, :integer
    add_index :designations, :jurisdiction_id
  end
end
