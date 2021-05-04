class SearchController < ApplicationController
  include Concerns::Searchable
  after_action :enable_caching

  before_action :load_search, only: [:index, :search_results]

  def index
    categories = I18n.t('search.categories')
    cms_root_pages = Comfy::Cms::Page.root.children
    @categories = []

    categories.map do |category|
      cms_page = cms_root_pages.find_by(slug: category)
      if cms_page
        @categories << { id: cms_page.id.to_s, title: cms_page.label }
      else
        @categories << { id: category, title: category.capitalize }
      end
    end

    _options = {
      page: search_params[:requested_page],
      per_page: search_params[:items_per_page]
    }
    @results = Search::FullSerializer.new(@search, _options).serialize
  end

  def search_results
    _options = {
      page: search_params[:requested_page],
      per_page: search_params[:items_per_page]
    }

    @results = Search::FullSerializer.new(@search, _options).serialize
    
    render json: @results.to_json
  end

  def map
    render :index
  end

  def autocomplete
    search_term = search_params[:search_term]
    db_type = search_params[:type]
    index = search_params[:index]

    render json: Autocompletion.lookup(search_term, db_type, index)
  end

  private

  def search_params
    params.permit(:search_term, :type, :index, :requested_page, :items_per_page, :search_index, :filters)
  end
end
