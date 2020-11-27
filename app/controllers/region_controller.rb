class RegionController < ApplicationController
  before_action :load_vars
  before_action :build_stats, only: :show

  TABS_KEYS = %i[coverage message iucn governance sources designations sites].freeze

  include MapHelper

  def show
    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'pdf'], 'general', params[:iso].upcase)

    @total_pame = @region.protected_areas.with_pame_evaluations.count
    @total_wdpa = @region.protected_areas.wdpas.count

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      point_query_services: all_services_for_point_query
    }

    @map_options = {
      map: { boundsUrl: @region.extent_url }
    }

    helpers.opengraph_title_and_description_with_suffix(@region.name)
  end

  def build_stats
    @tabs = [{ id: 'wdpa', title: I18n.t('global.area-types.wdpa') }]
    @stats_data = build_standard_hash

    if has_oecms
      @stats_data.merge!(build_oecm_hash)
      @tabs.push({ id: 'wdpa_oecm', title: I18n.t('global.area-types.wdpa_oecm') }) 
    end
  end

  private

  def has_oecms
    @total_oecm = @region.protected_areas.oecms.count
    @total_oecm.positive?
  end

  def build_hash(tab)
    oecm = tab == :wdpa_oecm
    hash = {}

    # What this does is call the corresponding method in tab presenter to build
    # the value for each key, populating the hash
    hash[tab] = TABS_KEYS.map do |key|
      { "#{key}": @tab_presenter.send("#{key}", oecms_tab: oecm) }
    end.reduce(&:merge)

    hash
  end

  def build_standard_hash
    build_hash(:wdpa)
  end

  def build_oecm_hash
    build_hash(:wdpa_oecm)
  end

  def map_overlays
    overlays(['oecm', 'marine_wdpa', 'terrestrial_wdpa'])
  end

  def load_vars
    params[:iso]!="GL" or raise_404
    @region = Region.where(iso: params[:iso].upcase).first
    @region or raise_404
    @presenter = RegionPresenter.new @region
    @tab_presenter = TabPresenter.new(@region)
  end
end
