# frozen_string_literal: true

class CountryController < ApplicationController
  after_action :enable_caching
  before_action :load_essential_vars
  before_action :build_stats, only: :show
  before_action :calculate_national_designations_counts, only: :show

  include MapHelper
  include CountriesHelper

  TABS_KEYS = %i[coverage message iucn governance sources designations growth sites].freeze

  def show
    # Components above tabs
    @download_options = helpers.download_options(%w[csv shp gdb pdf], 'general', @country.iso_3)

    @flag_path = flag_path(@country.name)

    # exclude transboundary PAs where the PAME evaluation is associated only with another country
    @total_pame = @country.protected_areas.with_pame_evaluations.includes(pame_evaluations: :countries).where(pame_evaluations: { countries: { id: @country.id } }).count
    @total_wdpa = @country.protected_areas.wdpas.count

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      point_query_services: all_services_for_point_query
    }

    @map_options = {
      map: { boundsUrl: @country.extent_url }
    }

    helpers.opengraph_title_and_description_with_suffix(@country.name)

    respond_to do |format|
      format.html
      format.pdf do
        rasterizer = Rails.root.join('vendor/assets/javascripts/rasterize.js')
        url = url_for(action: :pdf, iso: @country.iso)
        dest_pdf = Rails.root.join("tmp/#{@country.iso}-country.pdf").to_s

        `phantomjs #{rasterizer} '#{url}' #{dest_pdf} A4`
        send_file dest_pdf, type: 'application/pdf'
      end
    end
  end

  def build_stats
    @tabs = [{ id: 'wdpa', title: I18n.t('global.area-types.wdpa') }]
    @stats_data = build_hash(:wdpa)
    @number_of_national_desinitions = get_number_of_national_desinitions

    if has_oecms
      @stats_data.merge!(build_oecm_hash)
      @tabs.push({ id: 'wdpa_oecm', title: I18n.t('global.area-types.wdpa_oecm') })
    end
  end

  def pdf
    @for_pdf = true
  end

  def protected_areas
    redirect_to search_path(main: 'country', country: @country.id)
  end

  private

  def get_number_of_national_desinitions
    number_of_national_desinitions = 0
    designations_list = @stats_data[:wdpa][:designations][:designations]
    designations_list.each do |designation|
      total = designation[:total]
      number_of_national_desinitions = total if designation[:type] == 'National' && total.is_a?(Integer)
    end
    number_of_national_desinitions
  end

  def has_oecms
    @total_oecm = @country.protected_areas.oecms.count
    @total_oecm.positive?
  end

  def calculate_national_designations_counts
    # ['National'] -> all avaliable juriidctions are in /app/presenters/designations_presenter.rb
    @wdpa_national_designations_count = @country_presenter.get_designations_list(['National'],only_unique_wdpa_ids: true, is_oecm: false).length
    @oecm_national_designations_count = @country_presenter.get_designations_list(['National'],only_unique_wdpa_ids: true, is_oecm: true).length
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

  def build_oecm_hash
    build_hash(:wdpa_oecm)
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

  def flag_path(country_name)
    character_replacements = {
      ' ' => '-',
      ',' => ''
    }

    path_string = country_name.downcase
    character_replacements.each { |key, val| path_string.gsub!(key, val) }

    ActionController::Base.helpers.image_url("flags/#{path_string}.svg")
  end
end
