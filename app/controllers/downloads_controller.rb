class DownloadsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    redirect_to Download.link_to(download_params['id'])
  end

  def create
    render json: Download.request(download_params)
  end

  def poll
    render json: Download.poll(download_params)
  end

  private

  # TODO Permit only the expected params
  def download_params
    params.permit!
  end

end
