class Api::SearchController < ApplicationController
  def points
    results = Search.search(
      params[:q],
      search_options(size: ProtectedArea.count)
    ).with_coords

    render json: results
  end

  def by_point
    render json: Search.search('',
      size: 1,
      filters: {
        location: {
          coords: [params[:lon], params[:lat]], distance: params[:distance]
        }
      }
    ).results
  end

  private

  def search_options extra_options
    options = {filters: filters}
    options[:page] = params[:page].to_i if params[:page].present?
    options.merge(extra_options)
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
