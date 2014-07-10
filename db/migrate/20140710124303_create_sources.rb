class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :title
      t.string :responsible_party
      t.string :responsible_email
      t.date :year
      t.string :language
      t.string :character_set
      t.string :reference_system
      t.string :scale
      t.text :lineage
      t.text :citation
      t.text :disclaimer

      t.timestamps
    end
  end
end
