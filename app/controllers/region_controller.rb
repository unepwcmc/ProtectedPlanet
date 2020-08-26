class RegionController < ApplicationController
  before_action :load_vars
  include MapHelper

  def show
    @iucn_categories = @region.protected_areas_per_iucn_category

    @iucn_categories_chart = @region.protected_areas_per_iucn_category
      .enum_for(:each_with_index)
      .map do |category, i|
      { 
        id: i+1,
        title: category['iucn_category_name'], 
        value: category['count'] 
      }
    end.to_json

    @governance_types = @region.protected_areas_per_governance

    @designations = @presenter.designations

    # For the stacked row chart percentages
    @designation_percentages = @designations.map do |designation|
      { percent: designation[:percent] }
    end.to_json

    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @total_oecm = @region.protected_areas.oecms.count
    @total_pame = @region.protected_areas.with_pame_evaluations.count
    @total_wdpa = @region.protected_areas.wdpas.count


    @region_pas = pas_sample
    @regionPasViewAllUrl = search_areas_path(filters: { location: { type: 'region', options: ["#{@region.name}"] } })


    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize
    }

    @map_options = {
      map: { boundsUrl: @region.extent_url }
    }

    helpers.opengraph_title_and_description_with_suffix(@region.name)
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
