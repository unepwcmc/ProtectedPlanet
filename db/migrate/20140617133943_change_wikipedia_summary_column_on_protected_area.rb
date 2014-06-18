class ChangeWikipediaSummaryColumnOnProtectedArea < ActiveRecord::Migration
  def change
    rename_column :protected_areas, :wikipedia_summary_id, :wikipedia_article_id
    add_index :protected_areas, :wikipedia_article_id
  end
end
