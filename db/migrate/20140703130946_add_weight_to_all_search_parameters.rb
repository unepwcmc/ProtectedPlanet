class AddWeightToAllSearchParameters < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          DROP MATERIALIZED VIEW IF EXISTS tsvector_search_documents;
          CREATE MATERIALIZED VIEW tsvector_search_documents AS
            SELECT pa.wdpa_id,
              setweight(to_tsvector('english'::regconfig, coalesce (public.first(pa.name), '')), 'A') ||
              setweight(to_tsvector(coalesce(public.first(c.language)::regconfig, 'simple'::regconfig), coalesce (unaccent(public.first(pa.original_name)), '')), 'B') ||
              setweight(to_tsvector('english'::regconfig, coalesce (string_agg(c.name, ' '), '')), 'C') ||
              setweight(to_tsvector('english'::regconfig, coalesce (string_agg(sl.english_name, ' '), '')), 'D')
            AS document
            FROM protected_areas pa

            LEFT JOIN countries_protected_areas cpa ON cpa.protected_area_id = pa.id
            LEFT JOIN countries c ON cpa.country_id = c.id
            LEFT JOIN sub_locations sl ON c.id = sl.country_id

            GROUP BY pa.wdpa_id;
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP MATERIALIZED VIEW tsvector_search_documents;
        SQL
      end
    end

    add_index :tsvector_search_documents, :document, using: :gin
  end
end
