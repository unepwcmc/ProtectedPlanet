class SearchWdpaController < ApplicationController
  include Concerns::Searchable
  include Concerns::Filterable

  before_action :ignore_empty_query, only: [:index]
  before_action :load_search, only: [:index]
  before_action :load_filters, only: [:index]

  def index
    @search_area_types = [
      { id: 'wdpa', title: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.search-wdpa') }
    ].to_json

    @results = Search::AreasSerializer.new(@search).serialize
    @query = params['search_term']

    render json: @results
  end

  private

  def search_params
    params.permit(:search_term, :filters)
  end
end