class CreateProjectItems < ActiveRecord::Migration
  def change
    create_table :project_items do |t|
      t.references :project, index: true
      t.references :item, polymorphic: true

      t.timestamps
    end
  end
end
