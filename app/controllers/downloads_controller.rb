class DownloadsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    # Download.link_to returns an external S3 URL. Rails 7's
    # raise_on_open_redirects (on via load_defaults 7.0) blocks off-host
    # redirects unless explicitly allowed.
    redirect_to Download.link_to(download_params['id']), allow_other_host: true
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
