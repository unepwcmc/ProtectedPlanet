class ProjectsController < ApplicationController
  before_action :authenticate_user!

  ITEM_TYPES = {
    'region' => Region,
    'country' => Country,
    'protected_area' => ProtectedArea
  }

  def index
    @projects = current_user.projects
  end

  def create
    project = Project.create(name: "New Project", user: current_user)
    project.items << item

    redirect_to action: :index
  end

  def update
    @project = Project.find(params[:id])
    render(status: 404) and return if @project.nil?

    if item
      add_item_to_project
      redirect_to action: :index
    else
      @project.update_attributes(project_params)
      render json: true
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to projects_path
  end

  private

  def add_item_to_project
    unless @project.items.include? item
      @project.items << item
      ProjectDownloadsGenerator.perform_async @project.id
    end
  end

  def item
    @item ||= begin
      item_id = params[:item_id]
      item_class = ITEM_TYPES[params[:item_type]]

      item_class and item_class.find(item_id)
    end
  end

  def project_params
    params.require(:project).permit(:name)
  end
end
