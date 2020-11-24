# frozen_string_literal: true
require 'enumerator'

class CountryController < ApplicationController
  after_action :enable_caching
  before_action :load_essential_vars, except: %i[codes compare]
  before_action :build_stats, only: :show

  include MapHelper

  def show
    @country_presenter = CountryPresenter.new @country

    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'pdf'], 'general', @country.iso_3)

    @flag_path = ActionController::Base.helpers.image_url("flags/#{@country.name.downcase}.svg"),
   
    @sitesViewAllUrl = search_areas_path(filters: { location: { type: 'country', options: ["#{@country.name}"] } })

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
    @stats_data = build_standard_hash
    @stats_data.merge(build_oecm_hash) if has_oecms
    @stats_data.to_json
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
    @iucn_categories_oecm ||= @country.protected_areas_per_iucn_category
    @governance_types_oecm ||= @country.protected_areas_per_governance
    @coverage_growth_oecm ||= @country_presenter.coverage_growth_chart
    @terrestrial_combined_stats ||= @country_presenter.terrestrial_combined_stats
    @marine_combined_stats ||= @country_presenter.marine_combined_stats
    # TODO - Need to create a new method that factors in/out OECMs
    # For designations, sites and oecms
    @designation_percentages_oecm ||= @country_presenter.designations.map do |designation|
                                  { percent: designation[:percent] }
                                end.to_json
    @sites_oecm = @country.pas_sample
    @sources_oecm = @country.sources_per_country
  end

  def build_standard_hash
    load_assorted_vars

    {
      wdpa: {
        coverage: [
          @terrestrial_stats,
          @marine_stats
        ],
        iucn: {},
        governance: {},
        sources: @sources,
        designations: @designation_percentages,
        growth: '',
        sites: @sites
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
        iucn: {},
        governance: {},
        sources: @sources_oecm,
        designations: @designation_percentages_oecm,
        growth: '',
        sites: @sites_oecm
      }
    }
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
  end

  def load_assorted_vars
    @iucn_categories ||= @country.protected_areas_per_iucn_category(exclude_oecms: true)
    @governance_types ||= @country.protected_areas_per_governance(exclude_oecms: true)
    @coverage_growth ||= @country_presenter.coverage_growth_chart(exclude_oecms: true)
    @terrestrial_stats ||= @country_presenter.terrestrial_stats
    @marine_stats ||= @country_presenter.marine_stats
    @designation_percentages ||= @country_presenter.designations.map do |designation|
                                { percent: designation[:percent] }
                              end.to_json
    @sites = @country.pas_sample
    @sources = @country.sources_per_country
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
