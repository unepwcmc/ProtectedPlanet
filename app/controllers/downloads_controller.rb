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

  def update
    download_params.merge!({'email' => user_email})
    render status: 200, json: Download.set_email(download_params)
  end

  private

  # TODO Permit only the expected params
  def download_params
    params.permit!
  end

  def user_email
    download_params[:email] || current_user.try(:email)
  end
end
