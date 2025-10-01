class Api::V3::ProtectedAreasController < ApplicationController
  def show
    protected_area = ProtectedArea
      .without_geometry
      .where('site_id = ?', params[:id])
      .first

    if protected_area
      render json: protected_area.as_api_feeder
    else
      head 404, 'content_type' => 'text/plain'
    end
  end

  def geojson
    protected_area = ProtectedArea.find_by(site_id: params[:id])
    render text: URI.decode(protected_area.geojson)
  end

  def overlap
    protected_area = ProtectedArea.find_by(site_id: params[:id])
    comparison_protected_area = ProtectedArea
      .find_by(site_id: params[:comparison_site_id])

    render json: protected_area.overlap(comparison_protected_area)
  end
end
