class ProjectsController < ApplicationController
  before_action :authenticate_user!

  ITEM_TYPES = {
    region: Region,
    country: Country,
    protected_area: ProtectedArea
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

    respond_to do |format|
      if @project.update_attributes(project_params)
        format.html { redirect_to projects_path, :notice => 'Project was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "index" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def item
    item_id = params[:item_id]
    item_class = ITEM_TYPES[params[:item_type].to_sym]

    item_class.find(item_id)
  end

  def project_params
    params.require(:project).permit(:name)
  end

end
