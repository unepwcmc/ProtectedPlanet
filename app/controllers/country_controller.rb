# frozen_string_literal: true
require 'enumerator'

class CountryController < ApplicationController
  after_action :enable_caching
  before_action :load_essential_vars, except: %i[codes compare]
  before_action :build_stats, only: :show

  include MapHelper
  include CountriesHelper

  def show
     # Components above tabs
    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'pdf'], 'general', @country.iso_3)

    @flag_path = ActionController::Base.helpers.image_url("flags/#{@country.name.downcase}.svg")

    @total_pame = @country.protected_areas.with_pame_evaluations.count
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
    @stats_data = build_standard_hash

    if has_oecms
      @stats_data.merge!(build_oecm_hash) 
      @tabs.push({ id: 'wdpa_oecm', title: I18n.t('global.area-types.wdpa_oecm') }) 
    end
  end

  def pdf
    @for_pdf = true
  end

  def codes
    countries = Country.order(:name).pluck(:name, :iso_3)
    csv = CSV.generate do |rows|
      rows << %w[Name ISO3]
      countries.each(&rows.method(:<<))
    end

    send_data csv, filename: 'protectedplanet-country-codes.csv'
  end

  def compare
    # Removed in PP 2.0, redirects to simple country page
    redirect_to country_path(params[:iso])
  end

  def protected_areas
    redirect_to search_path(main: 'country', country: @country.id)
  end

  private

  def has_oecms
    @total_oecm = @country.protected_areas.oecms.count
    @total_oecm.positive?
  end

  def build_standard_hash
    load_assorted_vars

    {
      wdpa: {
        coverage: [
          @terrestrial_stats,
          @marine_stats
        ],
        message: {
          documents: @country_presenter.documents, #need to add translated text for link to documents hash 
          text: I18n.t('stats.warning'),
          link: I18n.t('global.button.link')
        },
        iucn: {
          chart: @iucn_categories,
          country: @country.name,
          categories: create_chart_links(@country.protected_areas_per_iucn_category(exclude_oecms: true)), 
          title: I18n.t('stats.iucn-categories.title')
        },
        governance: {
          chart: @governance_types,
          country: @country.name,
          governance: create_chart_links(@country.protected_areas_per_governance(exclude_oecms: true)), 
          title: I18n.t('stats.governance.title')
        },
        sources: {
          count: @sources.count,
          source_updated: I18n.t('stats.sources.updated'),
          sources: @sources,
          title: I18n.t('stats.sources.title')
        },
        designations: {
          chart: @designation_percentages,
          designations: create_chart_links(@country_presenter.designations(exclude_oecms: true), true),
          title: I18n.t('stats.designations.title')
        },
        growth: {
          chart: @coverage_growth,
          smallprint: I18n.t('stats.coverage-chart-smallprint'),
          title: I18n.t('stats.growth.title_wdpa')
        },
        sites: {
          cards: @sites,
          title: @country.name + ' ' + I18n.t('global.area-types.wdpa'),
          view_all: @sitesViewAllUrlWdpa,
          text_view_all: I18n.t('global.button.all')
        }
      }
    }
  end

  def build_oecm_hash
    assign_oecm_variables

    {
      wdpa_oecm: {
        coverage: [
          @terrestrial_combined_stats, 
          @marine_combined_stats
        ],
        message: {
          documents: @country_presenter.documents, 
          text: I18n.t('stats.warning_wdpa_oecm'),
          link: I18n.t('global.button.link')
        },
        iucn: {
          chart: @iucn_categories_oecm, 
          country: @country.name,
          categories: create_chart_links(@country.protected_areas_per_iucn_category), 
          title: I18n.t('stats.iucn-categories.title') #same as wdpa only 
        },
        governance: {
          chart: @governance_types_oecm, 
          country: @country.name,
          governance: create_chart_links(@country.protected_areas_per_governance), 
          title: I18n.t('stats.governance.title')#same as wdpa only 
        },
        sources: {
          count: @sources_oecm.count,  # needs to be sources for WDPA and OECMs
          source_updated: I18n.t('stats.sources.updated'),#same as wdpa only
          sources: @sources_oecm,# needs to be sources for WDPA and OECMs
          title: I18n.t('stats.sources.title')#same as wdpa only 
        },
        designations: {
          chart: @designation_percentages_oecm,
          designations: @country_presenter.designations,
          title: I18n.t('stats.designations.title') #same as wdpa only
        },
        growth: {
          chart: @growth_oecm, 
          smallprint: I18n.t('stats.coverage-chart-smallprint'), #same as wdpa only
          title: I18n.t('stats.growth.title_wdpa_oecm') #different
        },
        sites: {
          cards: @sites_oecm, 
          title: @country.name + ' ' + I18n.t('global.area-types.wdpa_oecm'),#different
          view_all: @sitesViewAllUrl,
          text_view_all: I18n.t('global.button.all')#same as wdpa only
        }
      }
    }
  end

  def map_overlays
    overlays(['oecm', 'marine_wdpa', 'terrestrial_wdpa'])
  end

  def load_essential_vars
    @country = if params[:iso].size == 2
                 Country.where(iso: params[:iso].upcase).first
               else
                 Country.where(iso_3: params[:iso].upcase).first
    end

    @country or raise_404

    @pame_statistics = @country.pame_statistic
    @country_presenter = CountryPresenter.new @country
  end

  def load_assorted_vars
    @iucn_categories ||= @country_presenter.iucn_categories_chart(@country.protected_areas_per_iucn_category(exclude_oecms: true))
    @governance_types ||= @country_presenter.governance_chart(@country.protected_areas_per_governance(exclude_oecms: true))
    @coverage_growth ||= @country_presenter.coverage_growth_chart(exclude_oecms: true)
    @terrestrial_stats ||= @country_presenter.terrestrial_stats
    @marine_stats ||= @country_presenter.marine_stats
    @designation_percentages ||= @country_presenter.designations(exclude_oecms: true).map do |designation|
                                { percent: designation[:percent] }
                              end
    @sites = site_cards(3, false)
    @sources = @country.sources_per_country(exclude_oecms: true)
    @growth = @country_presenter.coverage_growth_chart(exclude_oecms: true)
    @sitesViewAllUrlWdpa = search_areas_path(filters: { location: { type: 'country', options: ["#{@country.name}"] },  db_type: ['wdpa'] })
  end

  def assign_oecm_variables    
    @iucn_categories_oecm ||= @country_presenter.iucn_categories_chart(@country.protected_areas_per_iucn_category)
    @governance_types_oecm ||= @country_presenter.governance_chart(@country.protected_areas_per_governance)
    @coverage_growth_oecm ||= @country_presenter.coverage_growth_chart
    @terrestrial_combined_stats ||= @country_presenter.terrestrial_combined_stats
    @marine_combined_stats ||= @country_presenter.marine_combined_stats
    @designation_percentages_oecm ||= @country_presenter.designations.map do |designation|
                                  { percent: designation[:percent] }
                                end
    @sites_oecm = site_cards
    @sources_oecm = @country.sources_per_country
    @growth_oecm = @country_presenter.coverage_growth_chart
    @sitesViewAllUrl = search_areas_path(filters: { location: { type: 'country', options: ["#{@country.name}"] } })
  end

  def site_cards(size = 3, show_oecm = true)
    if show_oecm 
      [
        @country.protected_areas.oecms.first,
        @country.protected_areas.take(2)
      ].flatten
    else
      @country.protected_areas.order(:name).first(size)
    end
  end

  def create_chart_links(input_data, is_designations=false)
    if is_designations
      input_data.map do |j|
        j[:jurisdictions] = j[:jurisdictions].map do |category|
          category.merge!({
            link: chart_link(category)[:link],
            title: chart_link(category)[:title]
          })
        end
      end
    end

    input_data.map do |category|
      category.merge!({
        link: chart_link(category)[:link],
        title: chart_link(category)[:title]
      })
    end
  end
end
