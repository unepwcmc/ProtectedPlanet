class SearchOecmController < ApplicationController
  include Concerns::Searchable
  include Concerns::Filterable

  before_action :ignore_empty_query, only: [:search]
  before_action :load_search, only: [:search]
  before_action :load_filters, only: [:index, :search]

  def index
  end

  def search
    @results = Search::FullSerializer.new(@search, {page: params['requested_page']}).serialize

    render json: @results
  end
end
