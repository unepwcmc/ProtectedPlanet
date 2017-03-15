class SearchController < ApplicationController
  after_filter :enable_caching

  before_filter :ignore_empty_query, only: [:index, :map]
  before_filter :load_search, only: [:index, :map]

  def index
    render partial: 'grid' if request.xhr?
  end

  def map
    render :index
  end

  def autocomplete
    @results = Autocompletion.lookup params[:q]

    render partial: 'search/autocomplete'
  end

  private

  def ignore_empty_query
    @query = params[:q]
    redirect_to :root if @query.blank? && filters.empty?
  end

  def load_search
    begin
      @search = Search.search(@query, search_options)
    rescue => e
      Rails.logger.warn("error in search controller: #{e.message}")
      @search = nil
    end

    @main_filter = params[:main]
  end

  def search_options
    options = {filters: filters}
    options[:page] = params[:page].to_i if params[:page].present?
    options
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
