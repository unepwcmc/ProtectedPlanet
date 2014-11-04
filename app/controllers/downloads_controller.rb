class DownloadsController < ApplicationController
  def show
    country_iso_3 = params[:id]
    type = params[:type]

    redirect_to Download.link_to(country_iso_3, type)
  end

  def create
    search = Search.download(params[:q], options)
    render json: {token: search.token}
  end

  def poll
    search = Search.find(params[:token])
    render(search ? {json: search.properties} : {status: 404})
  end

  private

  def options
    {filters: filters}.tap { |options|
      options[:email] = current_user.email if current_user.present?
    }
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
