class DownloadsController < ApplicationController
  def show
    country_iso_3 = params[:id]
    type = params[:type]

    redirect_to Download.link_to(country_iso_3, type)
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
    search = Search.find(params[:token])
    render(search ? {json: search.properties} : {status: 404})
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
