class ProtectedAreasController < ApplicationController
  after_filter :record_visit
  after_filter :enable_caching

  def show
    id = params[:id]
    @protected_area = ProtectedArea.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first

    @protected_area or raise_404

    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry
    @other_designations = load_other_designations
    @networks = load_networks

    @wikipedia_article = @protected_area.try(:wikipedia_article)
  end

  private


  def record_visit
    return if @protected_area.nil?

    year_month = DateTime.now.strftime("%m-%Y")
    $redis.zincrby(year_month, 1, @protected_area.wdpa_id)
  end

  def load_other_designations
    other_designations = @protected_area.networks.detect(&:designation).try(:protected_areas)

    other_designations = Array.wrap(other_designations)
    other_designations.reject { |pa| pa.id == @protected_area.id }
  end

  TRANSBOUNDARY_SITES = "Transboundary sites".freeze
  def load_networks
    networks = @protected_area.networks.reject(&:designation)
    # ensure that transboundary sites network always appears first
    networks.sort { |a,b| a.name == TRANSBOUNDARY_SITES ? -1 : a.name <=> b.name }
  end
end
