class CreateWikipediaSummaries < ActiveRecord::Migration
  def change
    create_table :wikipedia_summaries do |t|
      t.text :summary
      t.string :image_url
      t.string :article_url
      t.timestamps
    end

    add_column :protected_areas, :wikipedia_summary_id, :integer
  end
end
