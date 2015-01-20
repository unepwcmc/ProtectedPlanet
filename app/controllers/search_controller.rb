class SearchController < ApplicationController
  after_filter :enable_caching
  before_action :authenticate_user!, only: [:create]

  before_filter :ignore_empty_query, only: [:index, :map]

  def index
    @search = Search.search(@query, search_options)
    render partial: 'grid' if params[:grid]
  end

  def map
    @search = Search.search(@query, search_options)
    render :index
  end

  def create
    SavedSearch.create(search_params.merge({project_id: project.id}))
    DownloadWorkers::Project.perform_async @project.id

    redirect_to projects_path
  end

  def autocomplete
    @results = Autocompletion.lookup params[:q]

    render partial: 'search/autocomplete'
  end

  private

  def ignore_empty_query
    @query = params[:q]
    redirect_to :root if @query.blank?
  end

  def project
    find_by = {id: search_params[:project_id], user: current_user}

    @project ||= Project.find_or_create_by(find_by) do |project|
      project.name = "New Project"
    end
  end

  def search_params
    params.permit(:search_term, :filters, :project_id)
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
