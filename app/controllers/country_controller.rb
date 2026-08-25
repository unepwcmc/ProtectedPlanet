# frozen_string_literal: true

class CountryController < ApplicationController
  before_action :load_essential_vars
  before_action :build_stats, only: %i[show]
  before_action :calculate_national_designations_counts, only: %i[show]
  after_action :enable_caching
  
  include MapHelper
  include CountriesHelper

  TABS_KEYS = %i[coverage message iucn governance sources designations growth sites].freeze

  def show
    load_show_data

    respond_to do |format|
      format.html
    end
  end

  def build_stats
    cache_key = [
      'country',
      'stats',
      @country.iso_3,
      Download::Config.current_label
    ].join(':')

    cached = Rails.cache.fetch(cache_key, expires_in: CACHE_FETCH_TTL) do
      total_oecm = @country.protected_areas.oecms.count
      tabs = [{ id: 'wdpa', title: I18n.t('global.area-types.wdpca') }]
      stats_data = build_hash(:wdpa)

      if total_oecm.positive?
        stats_data.merge!(build_hash(:wdpa_oecm))
        tabs.push({ id: 'wdpa_oecm', title: I18n.t('global.area-types.wdpca_oecm') })
      end

      { tabs: tabs, stats_data: stats_data, total_oecm: total_oecm }
    end

    @tabs = cached[:tabs]
    @stats_data = cached[:stats_data]
    @total_oecm = cached[:total_oecm]
  end

  def protected_areas
    redirect_to search_path(main: 'country', country: @country.id)
  end

  private

  # Shared by :show and :pdf, which render the same template.
  def load_show_data
    # Components above tabs
    @download_options = helpers.download_options(%w[csv shp gdb pdf], 'general', @country.iso_3)

    @flag_path = helpers.flag_url(@country.iso_3)

    # Exclude transboundary PAs where the PAME evaluation is associated only with another country.
    @total_pame = @country
      .protected_areas
      .pas_with_pame_on_self_only
      .joins(pame_evaluations: :countries)
      .where(countries: { id: @country.id })
      .distinct
      .count
    @total_wdpa = @country.protected_areas.wdpas.count

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      point_query_services: all_services_for_point_query,
      title: map_yml[:title],
      popup_attributes: map_yml[:popup_attributes],
      disclaimer: map_yml[:disclaimer]
    }

    @map_options = {
      map: { boundsUrl: @country.extent_url }
    }

    helpers.opengraph_title_and_description_with_suffix(@country.name)
    set_page_meta(title: @country.name, description: t('meta.country.description', name: @country.name))
    @structured_data = country_structured_data
  end

  # An administrative area, not the website. containsPlace is deliberately absent:
  # a country holds thousands of protected areas and enumerating them here would
  # be a huge payload that the sitemap already covers properly.
  def country_structured_data
    {
      '@context': 'https://schema.org',
      '@type': 'Country',
      name: @country.name,
      # See ProtectedAreasController#place_structured_data: default_url_options
      # would append ?locale=en, disagreeing with the canonical link.
      url: canonical_url,
      description: t('meta.country.description', name: @country.name),
      identifier: [
        { '@type': 'PropertyValue', name: 'ISO 3166-1 alpha-3', value: @country.iso_3 },
        { '@type': 'PropertyValue', name: 'ISO 3166-1 alpha-2', value: @country.iso }
      ].reject { |identifier| identifier[:value].blank? }
    }
  end

  def calculate_national_designations_counts
    # ['National'] -> all avaliable juriidctions are in /app/presenters/designations_presenter.rb
    cache_key = [
      'country',
      'national_designations_counts',
      @country.iso_3,
      Download::Config.current_label
    ].join(':')

    cached = Rails.cache.fetch(cache_key, expires_in: CACHE_FETCH_TTL) do
      {
        wdpa: @country_presenter.get_designations_list(['National'],
          only_unique_site_ids: true, is_oecm: false).length,
        oecm: @country_presenter.get_designations_list(['National'],
          only_unique_site_ids: true, is_oecm: true).length
      }
    end

    @wdpa_national_designations_count = cached[:wdpa]
    @oecm_national_designations_count = cached[:oecm]
  end

  def build_hash(tab)
    hash = {}

    # What this does is call the corresponding method in tab presenter to build
    # the value for each key, populating the hash
    hash[tab] = TABS_KEYS.map do |key|
      { "#{key}": @tab_presenter.send(key.to_s, oecms_tab: tab == :wdpa_oecm) }
    end.reduce(&:merge)

    hash
  end

  def map_overlays
    overlays(%w[oecm marine_wdpa terrestrial_wdpa])
  end

  def load_essential_vars
    @country = Country.find_by(iso_3: params[:iso].upcase)

    @country or raise_404

    @country_presenter = CountryPresenter.new(@country)
    @tab_presenter = TabPresenter.new(@country)
  end
end
