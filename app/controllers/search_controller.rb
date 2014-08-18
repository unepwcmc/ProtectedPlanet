class SearchController < ApplicationController
  before_filter :convert_integer_filters

  def index
    return unless @query = params[:q]

    @search = Search.search(@query, {filters: filters})
  end

  private

  ALLOWED_FILTERS = ['type', 'country', 'iucn_category', 'designation', 'region']
  INTEGER_FILTERS = ['country', 'iucn_category', 'designation', 'region']

  def filters
    filters = []

    params.each do |param, value|
      filters.push({name: param, value: value}) if ALLOWED_FILTERS.include? param
    end

    filters
  end

  # Rails params are passed as string, but Elastic Search depends on
  # queries being given as the correct types.
  def convert_integer_filters
    INTEGER_FILTERS.each do |filter_name|
      if params[filter_name].present?
        params[filter_name] = params[filter_name].to_i
      end
    end
  end
end
