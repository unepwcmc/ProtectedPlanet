class AdminController < ApplicationController
  protect_from_forgery :except => [:clear_cache, :maintenance]

  def maintenance
    unless authenticated?
      return render json: {message: 'unauthorised'}, status: 401
    end

    if maintenance_mode_on
      maintenance_file.write
    else
      maintenance_file.delete
    end

    render json: {message: 'success'}
  end

  def clear_cache
    unless authenticated?
      return render json: {message: 'unauthorised'}, status: 401
    end

    Rails.cache.clear

    render json: {message: 'success'}
  end

  private

  def authenticated?
    authentication_key = Rails.application.secrets.maintenance_mode_key
    request.headers['X-Auth-Key'] == authentication_key
  end

  def maintenance_mode_on
    params[:maintenance_mode_on] == "true"
  end

  def maintenance_file
    file = Turnout::MaintenanceFile.default
    file.import_env_vars "allowed_paths" => ["/admin/maintenance", "/admin/sidekiq"]
    file
  end
end
