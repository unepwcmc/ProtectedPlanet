class Api::V3::SearchController < ApplicationController
  def by_point
    dirty_query = """
      SELECT p.id, p.site_id, p.name, p.the_geom_latitude, p.the_geom_longitude
      FROM protected_areas p
      WHERE ST_DWithin(p.the_geom, ST_GeomFromText('POINT(? ?)',4326), 0.0000001)
      LIMIT 1;
    """.squish

    query = ActiveRecord::Base.send(:sanitize_sql_array, [
      dirty_query, params[:lon].to_f, params[:lat].to_f
    ])

    results = db.execute(query)

    render json: results
  end

  private

  def db
    ActiveRecord::Base.connection
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
