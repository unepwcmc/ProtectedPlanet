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

  def geojson
    protected_area = ProtectedArea.find_by(wdpa_id: params[:id])
    render text: URI.decode(protected_area.geojson)
  end
end
