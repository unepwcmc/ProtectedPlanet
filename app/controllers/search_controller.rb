class SearchController < ApplicationController
  def index
    return unless @query = params[:q]

    @search = Search.search(@query, {filters: filters})
  end

  private

  ALLOWED_FILTERS = ['type']

  def filters
    filters = []

    params.each do |param, value|
      filters.push({name: param, value: value}) if ALLOWED_FILTERS.include? param
    end

    filters
  end
end
