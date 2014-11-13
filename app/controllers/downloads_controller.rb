class DownloadsController < ApplicationController
  def show
    type = params[:type]

    json = if params[:domain] == 'general'
      country_iso_3 = params[:id]
      {link: Download.link_to(country_iso_3, type)}
    elsif params[:domain] == 'project'
      project = Project.find(params[:id])
      project.download_info
    end

    render json: json
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
      render(project ? {json: project.download_info} : {status: 404})
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
