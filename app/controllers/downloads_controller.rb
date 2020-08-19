class DownloadsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    redirect_to Download.link_to(params['id'])
  end

  def create
    render json: Download.request(params)
  end

  def poll
    render json: Download.poll(params)
  end

  def update
    params.merge!({'email' => user_email})
    render status: 200, json: Download.set_email(params)
  end

  private

  def user_email
    params[:email] || current_user.try(:email)
  end
end
