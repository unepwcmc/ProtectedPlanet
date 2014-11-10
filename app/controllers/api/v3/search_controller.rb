class Api::V3::SearchController < ApplicationController
  def points
    results = Search.search(
      params[:q],
      search_options(size: ProtectedArea.count)
    ).with_coords

    render json: results
  end

  def by_point
    dirty_query = """
      SELECT p.id, p.wdpa_id, p.name, p.the_geom_latitude, p.the_geom_longitude
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

  def search_options extra_options
    options = {filters: filters}
    options[:page] = params[:page].to_i if params[:page].present?
    options.merge(extra_options)
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
