class AddSearchView < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        # create an aggregate to return the first element in a set
        execute <<-SQL
          CREATE OR REPLACE FUNCTION public.first_agg ( anyelement, anyelement )
          RETURNS anyelement LANGUAGE sql IMMUTABLE STRICT AS $$
            SELECT $1;
          $$;

          CREATE AGGREGATE public.first (
            sfunc    = public.first_agg,
            basetype = anyelement,
            stype    = anyelement
          );
        SQL

        execute <<-SQL
          DROP MATERIALIZED VIEW IF EXISTS tsvector_search_documents;
          CREATE MATERIALIZED VIEW tsvector_search_documents AS
            SELECT pa.wdpa_id,
              setweight(to_tsvector('english'::regconfig, coalesce (string_agg(c.name, ' '), '')), 'B') ||
              setweight(to_tsvector('english'::regconfig, coalesce (public.first(pa.name), '')), 'A') ||
              to_tsvector(coalesce(public.first(c.language)::regconfig, 'simple'::regconfig), coalesce (unaccent(public.first(pa.original_name)), '')) ||
              to_tsvector('english'::regconfig, coalesce (string_agg(sl.english_name, ' '), '')) ||
              to_tsvector(coalesce(public.first(c.language::regconfig), 'simple'::regconfig), coalesce (string_agg(sl.alternate_name, ' '), ''))
            AS document
            FROM protected_areas pa

            LEFT JOIN countries_protected_areas cpa ON cpa.protected_area_id = pa.id
            LEFT JOIN countries c ON cpa.country_id = c.id
            LEFT JOIN sub_locations sl ON c.id = sl.country_id

            GROUP BY pa.wdpa_id
            ORDER BY pa.wdpa_id;
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
