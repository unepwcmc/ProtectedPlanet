class UpdateSearchViewForNullLanguages < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          DROP MATERIALIZED VIEW tsvector_search_documents;
          CREATE MATERIALIZED VIEW tsvector_search_documents AS
            SELECT pa.id,
              setweight(to_tsvector('english'::regconfig, coalesce (string_agg(c.name, ' '), '')), 'B') ||
              setweight(to_tsvector('english'::regconfig, coalesce (pa.name, '')), 'A') ||
              to_tsvector(coalesce(public.first(c.language)::regconfig, 'simple'::regconfig), coalesce (unaccent(pa.original_name), '')) ||
              to_tsvector('english'::regconfig, coalesce (string_agg(sl.english_name, ''))) ||
              to_tsvector(coalesce(public.first(c.language::regconfig), 'simple'::regconfig), coalesce (string_agg(sl.alternate_name, '')))
            AS document
            FROM protected_areas pa

            LEFT JOIN countries_protected_areas cpa ON cpa.protected_area_id = pa.id
            LEFT JOIN countries c ON cpa.country_id = c.id
            LEFT JOIN sub_locations sl ON c.id = sl.country_id

            GROUP BY pa.id
            ORDER BY pa.id;
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP MATERIALIZED VIEW tsvector_search_documents;
        SQL
      end
    end
  end
end
