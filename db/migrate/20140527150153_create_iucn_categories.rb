class CreateIucnCategories < ActiveRecord::Migration
  def change
    create_table :iucn_categories do |t|
      t.string :name

      t.timestamps
    end
  end
end
