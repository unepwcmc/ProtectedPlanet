class ProjectsController < ApplicationController
  ITEM_TYPES = {
    region: Region,
    country: Country,
    protected_area: ProtectedArea
  }

  def index
  end

  def create
    item_id = params[:first_item_id]
    item_class = ITEM_TYPES[params[:first_item_type].to_sym]
    item = item_class.find(item_id)

    project = Project.create(name: "New Project")
    project.items << item

    redirect_to action: :index
  end
end
