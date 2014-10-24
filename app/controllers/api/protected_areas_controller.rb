class Api::ProtectedAreasController < ApplicationController
  def index
    @protected_areas = {}
    if wdpa_id = params[:wdpa_id]
      @protected_areas = ProtectedArea.
                         without_geometry.
                         where('wdpa_id = ?', wdpa_id.to_i).
                         first.
                         as_api_feeder
    end

    render json: @protected_areas, status: 200
  end
end