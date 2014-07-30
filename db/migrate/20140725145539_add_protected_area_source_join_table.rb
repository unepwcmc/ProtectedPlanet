class AddProtectedAreaSourceJoinTable < ActiveRecord::Migration
  def change
    create_table :protected_areas_sources, :id => false do |t|
      t.references :protected_area
      t.references :source
    end

    add_index :protected_areas_sources, [:protected_area_id, :source_id],
      name: 'index_protected_areas_sources_composite'
    add_index :protected_areas_sources, :source_id
  end
end
