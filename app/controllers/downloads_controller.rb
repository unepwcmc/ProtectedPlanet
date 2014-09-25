class DownloadsController < ApplicationController
  def show
    country_iso_3 = params[:id]
    type = params[:type]

    redirect_to Download.link_to(country_iso_3, type)
  end

  def create
    search = Search.download(params[:q], {filters: filters})
    render json: {token: search.token}
  end

  private
  def filters
    params.permit(Search::ALLOWED_FILTERS)
  end
end
