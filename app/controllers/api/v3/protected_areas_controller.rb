class Api::V3::ProtectedAreasController < ApplicationController
  def show
    protected_area = ProtectedArea.
      without_geometry.
      where('wdpa_id = ?', params[:id]).
      first

    if protected_area
      render json: protected_area.as_api_feeder
    else
      head 404, "content_type" => 'text/plain'
    end
  end
end
