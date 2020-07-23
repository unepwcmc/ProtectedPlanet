class RegionController < ApplicationController
  before_action :load_vars
  include MapHelper

  def show
    @iucn_categories = @region.protected_areas_per_iucn_category

    @governance_types = @region.protected_areas_per_governance

    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @total_oecm = 0 ##TODO
    @total_wdpa = @region.protected_areas.count

    @wdpa = pas_sample

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize
    }

    @map_options = {
      map: { boundsUrl: region_extent_url(@region.name) }
    }
  end

  private

  def map_overlays
    overlays(['oecm', 'marine_wdpa', 'terrestrial_wdpa'])
  end

  def load_vars
    params[:iso]!="GL" or raise_404
    @region = Region.where(iso: params[:iso].upcase).first
    @region or raise_404
    @presenter = RegionPresenter.new @region
  end

  def pas_sample(size=3)
    ProtectedArea.joins(:countries).
      where("countries.region_id = #{@region.id}").
      order(:name).first(size)
  end
end
