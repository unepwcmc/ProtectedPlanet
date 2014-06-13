class AddSearchViewIndex < ActiveRecord::Migration
  def change
    add_index :tsvector_search_documents, :document, using: :gin
  end
end
