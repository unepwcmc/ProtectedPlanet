class CartoDbMerger
  def merge table_names
    @table_names = table_names
    @columns =  "the_geom, wdpaid, wdpa_pid, name, orig_name, country, sub_loc, desig, desig_eng, desig_type, iucn_cat, int_crit, marine, rep_m_area, gis_m_area, rep_area, gis_area, status, status_yr, gov_type, mang_auth, mang_plan, no_take, no_tk_area, metadataid, shape_leng, shape_area"

    cartodb_username = Rails.application.secrets.cartodb_username
    cartodb_api_key  = Rails.application.secrets.cartodb_api_key
    cartodb_url      = "http://#{cartodb_username}.cartodb.com/api/v2/sql"

    Typhoeus.get(cartodb_url,
      params: {
        q: merge_query,
        api_key: cartodb_api_key
      }
    )
  end

   private

  def merge_query
    "INSERT INTO #{@table_names[0]} (#{union_tables_query})"
  end

  def union_tables_query
    table_queries = @table_names.drop(1).map { |table_name| "SELECT #{@columns} FROM #{table_name}" }
    table_queries.join(' UNION ALL ')
  end
end