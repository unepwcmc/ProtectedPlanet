class SearchController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  after_filter :enable_caching, only: [:index]

  def index
    return unless @query = params[:q]

    @search = Search.search(@query, search_options)
  end

  def create
    SavedSearch.create_and_populate(
      search_params.merge({project_id: project.id})
    )

    redirect_to projects_path
  end

  private

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
