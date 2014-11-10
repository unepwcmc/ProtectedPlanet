class DownloadsController < ApplicationController
  def show
    type = params[:type]

    link = if params[:domain] == 'general'
      country_iso_3 = params[:id]
      Download.link_to(country_iso_3, type)
    elsif params[:domain] == 'project'
      project_id = params[:id]
      Download.link_to "project_#{project_id}_all", type
    end

    render({json: {link: link}})
  end

  def create
    search = Search.download(params[:q], {filters: filters})
    set_email(search)

    render json: {token: search.token}
  end

  def update
    search = Search.find(params[:id])
    set_email(search)

    render(search ? {json: search.properties} : {status: 404})
  end

  def poll
    if params[:domain] == 'search'
      search = Search.find(params[:token])
      render(search ? {json: search.properties} : {status: 404})
    elsif params[:domain] == 'project'
      project = Project.find(params[:token])
      render(project ? {json: project.download_link} : {status: 404})
    end
  end

  private

  def set_email search
    email = params[:email] || current_user.try(:email)
    if email.present?
      search.properties['user_email'] = email
    end
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
