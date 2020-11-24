# frozen_string_literal: true
require 'enumerator'

class CountryController < ApplicationController
  after_action :enable_caching
  before_action :load_vars, except: %i[codes compare]

  include MapHelper

  def show
    @country_presenter = CountryPresenter.new @country

    # Components above tabs
    @total_pame = @country.protected_areas.with_pame_evaluations.count
    @total_wdpa = @country.protected_areas.wdpas.count

    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'pdf'], 'general', @country.iso_3)

    @flag_path = ActionController::Base.helpers.image_url("flags/#{@country.name.downcase}.svg"),
   
    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize,
      point_query_services: all_services_for_point_query
    }

    @map_options = {
      map: { boundsUrl: @country.extent_url }
    }
    # End Components above tabs
    
    #  Variables that have an OECM counterpart
    @iucn_categories ||= @country.protected_areas_per_iucn_category(exclude_oecms: true)
    @governance_types ||= @country.protected_areas_per_governance(exclude_oecms: true)
    @coverage_growth ||= @country_presenter.coverage_growth_chart(exclude_oecms: true)
    @country_designations ||= @country_presenter.designations
    # For the stacked row chart percentages
    @designation_percentages = @country_designations.map do |designation|
      { percent: designation[:percent] }
    end

    @tabs = [
      { id: 'wdpa', title: I18n.t('global.area-types.wdpa') }, 
      { id: 'wdpa_oecm', title: I18n.t('global.area-types.wdpa_oecm') }
    ].to_json

    @stats_data = {
      wdpa: {
        coverage: [
          @country_presenter.terrestrial_stats,
          @country_presenter.marine_stats,
        ],
        message: {
          documents: @country_presenter.documents, #need to add translated text for link to documents hash 
          text: I18n.t('stats.warning')
        },
        iucn: { #SL don't edit yet
          # chart: @country_presenter.iucn_categories(iucn_categories),
          title: I18n.t('stats.iucn-categories.title')
        },
        governance: { #SL don't edit yet
          #chart: 
          title: I18n.t('stats.governance.title')
        },
        sources: {
          count: @country.sources_per_country.count,
          source_updated: I18n.t('stats.sources.updated'),
          sources: @country.sources_per_country,
          title: I18n.t('stats.sources.title')
        },
        designations: { #SL don't edit yet
          chart: @designation_percentages,
          designations: @country_designations,
          title: I18n.t('stats.designations.title')
        },
        growth: { #SL don't edit yet
          chart: @coverage_growth,
          smallprint: I18n.t('stats.coverage-chart-smallprint'),
          title: I18n.t('stats.growth.title_wdpa')
        },
        sites: { #SL don't edit yet
          cards: @country.protected_areas.take(3),
          title: @country.name + ' ' + I18n.t('country.protected_areas'),
          view_all: search_areas_path(filters: { location: { type: 'country', options: ["#{@country.name}"] } }),
          text_view_all: I18n.t('global.button.all')
        }
      },
      wdpa_oecm: {
        coverage: [
          @country_presenter.terrestrial_combined_stats,
          @country_presenter.marine_combined_stats,
        ],
        message: {
          documents: @country_presenter.documents, #same
          text: I18n.t('stats.warning_wdap_oecm') #different
        },
        iucn: { #SL don't edit yet
          # chart: @country_presenter.iucn_categories(iucn_categories),
          title: I18n.t('stats.iucn-categories.title')
        },
        governance: {},#SL don't edit yet
        sources: {
          count: @country.sources_per_country.count, # needs to include sources for OECMs
          source_updated: I18n.t('stats.sources.updated'), #same as wdpa only
          sources: @country.sources_per_country, # needs to include sources for OECMs
          title: I18n.t('stats.sources.title') #same as wdpa only
        },
        # designations:#SL don't edit yet
        growth: {#SL don't edit yet
          # chart: @coverage_growth, #different
          smallprint: I18n.t('stats.coverage-chart-smallprint'), #same as wdpa only
          title: I18n.t('stats.growth.title_wdpa_oecm') #different
        },
        # sites:#SL don't edit yet
      }
    }.to_json
    
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

  def assign_oecm_variables
    return unless has_oecms
    
    @iucn_categories_oecm ||= @country.protected_areas_per_iucn_category
    @governance_types_oecm ||= @country.protected_areas_per_governance
    @coverage_growth_oecm ||= @country_presenter.coverage_growth_chart
  end

  def map_overlays
    overlays(['oecm', 'marine_wdpa', 'terrestrial_wdpa'])
  end

  def load_vars
    @country = if params[:iso].size == 2
                 Country.where(iso: params[:iso].upcase).first
               else
                 Country.where(iso_3: params[:iso].upcase).first
    end

    @country or raise_404

    @pame_statistics = @country.pame_statistic
    @country_presenter = CountryPresenter.new @country
    assign_oecm_variables
  end

  def pas_sample(size = 3)
    iso = params[:iso].upcase
    pas = nil

    pas = if iso.size == 2
            ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'")
          else
            ProtectedArea.joins(:countries).where("countries.iso_3 = '#{iso}'")
          end

    pas.order(:name).first(size)
  end
end
