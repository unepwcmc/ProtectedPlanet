class Api::ProtectedAreasController < ApplicationController
  def show
    @protected_area = ProtectedArea.
                         without_geometry.
                         where('wdpa_id = ?', params[:wdpa_id]).
                         first.
                         as_api_feeder

    render json: @protected_area, status: 200
  end
end