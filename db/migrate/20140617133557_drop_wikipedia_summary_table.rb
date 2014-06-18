class DropWikipediaSummaryTable < ActiveRecord::Migration
  def change
    drop_table :wikipedia_summaries
  end
end
