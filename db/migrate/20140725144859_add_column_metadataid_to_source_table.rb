class AddColumnMetadataidToSourceTable < ActiveRecord::Migration
  def change
    add_column :sources, :metadataid, :integer
    add_index :sources, :metadataid
  end
end
