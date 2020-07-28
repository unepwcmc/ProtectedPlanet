class SearchController < Comfy::Cms::ContentController
  before_action :load_cms_page
  
  include Concerns::Searchable
  after_action :enable_caching

  before_action :ignore_empty_query, only: [ :search_results]
  before_action :load_search, only: [:search_results]

  def index
    categories = I18n.t('search.categories')
    cms_root_pages = Comfy::Cms::Page.root.children
    @categories = []

    categories.map do |category|
      cms_page = cms_root_pages.find_by(slug: category)
      if cms_page
        @categories << { id: cms_page.id.to_s, title: cms_page.label}
      else
        @categories << { id: category, title: category.capitalize }
      end
    end

    @query = search_params[:search_term]
  end

  def search_results
    _options = {
      page: search_params[:requested_page],
      per_page: search_params[:items_per_page]
    }
    @results = Search::FullSerializer.new(@search, _options).serialize

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
    params.permit(:search_term, :type, :requested_page, :items_per_page, :filters)
  end
end
