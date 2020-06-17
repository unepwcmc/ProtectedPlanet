class SearchController < ApplicationController
  include Concerns::Searchable
  after_action :enable_caching

  before_action :ignore_empty_query, only: [:search_results]
  before_action :load_search, only: [:search_results]

  def index
    @categories = [{ id: -1, title: 'All' }]
    Comfy::Cms::Page.root.children.map do |c|
      @categories << { id: c.id, title: c.label }
    end
    @categories = @categories.to_json

    @query = search_params[:search_term]
  end

  def search_results
    @results = Search::FullSerializer.new(@search, {page: search_params[:requested_page]}).serialize

    render json: @results
  end

  def map
    render :index
  end

  def autocomplete
    @results = Autocompletion.lookup(search_params[:search_term], search_params[:type])

    render json: @results
  end

  private

  def search_params
    params.permit(:search_term, :type, :requested_page, :items_per_page)
  end
end
