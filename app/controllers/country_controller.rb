# frozen_string_literal: true
require 'enumerator'

class CountryController < ApplicationController
  after_action :enable_caching
  before_action :load_vars, except: %i[codes compare]
  include MapHelper

  def show
    @country_presenter = CountryPresenter.new @country

    @flag_path = ActionController::Base.helpers.image_url("flags/#{@country.name.downcase}.svg"),
    @iucn_categories = @country.protected_areas_per_iucn_category
    
    @iucn_categories_chart = @country.protected_areas_per_iucn_category
      .enum_for(:each_with_index)
      .map do |category, i|
      { 
        id: i+1,
        title: category['iucn_category_name'], 
        value: category['count'] 
      }
    end.to_json

    @governance_types = @country.protected_areas_per_governance
    @coverage_growth = @country_presenter.coverage_growth 

    @country_designations = @country_presenter.designations

    # For the stacked row chart percentages
    @designation_percentages = @country_designations.map do |designation|
      { percent: designation[:percent] }
    end.to_json

    @sites = @country.protected_areas.take(3)
    @sitesViewAllUrl = search_areas_path(filters: { location: { type: 'country', options: ["#{@country.name}"] } })

    @sources = @country.sources_per_country

    @total_oecm = @country.protected_areas.oecms.count
    @total_pame = @country.protected_areas.with_pame_evaluations.count
    @total_wdpa = @country.protected_areas.wdpas.count

    @map = {
      overlays: MapOverlaysSerializer.new(map_overlays, map_yml).serialize
    }

    @map_options = {
      map: { boundsUrl: @country.extent_url }
    }
    
    ##TODO need adding
    # protected_national_report: statistic_presenter.percentage_nr_marine_cover, 
    # national_report_version: statistic_presenter.nr_version,

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
