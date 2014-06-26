class DownloadsController < ApplicationController
  def show
    country_iso_3 = params[:iso_3]
    type = params[:type]

    redirect_to Download.link_to(country_iso_3, type)
  end
end
