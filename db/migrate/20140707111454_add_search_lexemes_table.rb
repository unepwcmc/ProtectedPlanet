class AddSearchLexemesTable < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE EXTENSION pg_trgm;

          CREATE TABLE search_lexemes AS SELECT word FROM ts_stat('SELECT document FROM tsvector_search_documents');
          CREATE INDEX search_lexemes_idx ON search_lexemes USING gin(word gin_trgm_ops);
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP EXTENSION pg_trgm;
          DROP TABLE search_lexemes;
        SQL
      end
    end
  end
end
