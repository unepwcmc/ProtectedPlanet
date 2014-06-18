class CreateCountryStatistics < ActiveRecord::Migration
  def change
    create_table :country_statistics do |t|
      t.integer :country_id
      t.float :area
      t.float :pa_area
      t.float :percentage_cover_pas

      t.timestamps
    end
  end
end
