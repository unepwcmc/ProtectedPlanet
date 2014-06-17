class AddDetailsUrlToImage < ActiveRecord::Migration
  def change
    add_column :images, :details_url, :text
  end
end
