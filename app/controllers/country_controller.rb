class CountryController < ApplicationController
  after_action :enable_caching
  before_action :load_vars, except: [:codes, :compare]

  def show
    presenter = StatisticPresenter.new @country

    @designations = [
      {
        title: 'National designations',
        total: get_designation_total('National'),
        has_jurisdiction: has_jurisdiction('National'),
        jurisdictions: get_jurisdictions('National')
      }, 
      {
        title: 'Regional designations',
        total: get_designation_total('Regional'),
        has_jurisdiction: has_jurisdiction('Regional'),
        jurisdictions: get_jurisdictions('Regional')
      },
      {
        title: 'International designations',
        total: get_designation_total('International'),
        has_jurisdiction: has_jurisdiction('International'),
        jurisdictions: get_jurisdictions('International')
      }
    ]

    @flag_path = ActionController::Base.helpers.image_url("flags/#{@country.name.downcase}.svg"),
    
    @iucn_categories = @country.protected_areas_per_iucn_category

    @governance_types = @country.protected_areas_per_governance

    @marine_stats = {
      pame_km2: presenter.pame_statistic.pame_pa_marine_area,
      pame_percentage: presenter.pame_statistic.pame_percentage_pa_marine_cover.round(2),
      protected_km2: presenter.pa_marine_area.round(0),
      protected_percentage: presenter.percentage_pa_marine_cover.round(2),
      total_km2: presenter.marine_area.round(0)
    }

    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @terrestrial_stats = {
      pame_km2: presenter.pame_statistic.pame_pa_land_area,
      pame_percentage: presenter.pame_statistic.pame_percentage_pa_land_cover.round(2),
      protected_km2: presenter.pa_land_area.round(0),
      protected_percentage: presenter.percentage_pa_land_cover.round(2),
      total_km2: presenter.land_area.round(0)
    }

    @total_oecm = 0 ##TODO
    @total_pame = @country.protected_areas.with_pame_evaluations.count
    @total_points_percentage = presenter.geometry_ratio[:points]
    @total_polygons_percentage = presenter.geometry_ratio[:polygons] 
    @total_wdpa = @country.protected_areas.count

    @wdpa = get_wdpa
    
    ##TODO need adding
    # protected_national_report: presenter.percentage_nr_marine_cover, 
    # national_report_version: presenter.nr_version,

    respond_to do |format|
      format.html
      format.pdf {
        rasterizer = Rails.root.join("vendor/assets/javascripts/rasterize.js")
        url = url_for(action: :pdf, iso: @country.iso)
        dest_pdf = Rails.root.join("tmp/#{@country.iso}-country.pdf").to_s

        `phantomjs #{rasterizer} '#{url}' #{dest_pdf} A4`
        send_file dest_pdf, type: 'application/pdf'
      }
    end
  end

  def pdf
    @for_pdf = true
  end

  def codes
    countries = Country.order(:name).pluck(:name, :iso_3)
    csv = CSV.generate { |rows|
      rows << ["Name", "ISO3"]
      countries.each(&rows.method(:<<))
    }

    send_data csv, filename: 'protectedplanet-country-codes.csv'
  end

  def compare
    # Removed in PP 2.0, redirects to simple country page
    redirect_to country_path(params[:iso])
  end

  def protected_areas
    redirect_to search_path(main: "country", country: @country.id)
  end

  private

  def load_vars
    @country = if params[:iso].size == 2
      Country.where(iso: params[:iso].upcase).first
    else
      Country.where(iso_3: params[:iso].upcase).first
    end

    @country or raise_404

    @pame_statistics = @country.pame_statistic
  end

  def designations ##FERDI I am assuming a lot of this will be moved as it is used across region and countries
    designations_by_jurisdiction = @country.designations.group_by { |design|
      design.jurisdiction.name rescue "Not Reported"
    }
  end

  def has_jurisdiction type 
    Jurisdiction.find_by_name(type)
  end

  def get_designation_total type
    if designations.include? type then
      designations[type].count
    else
      0
    end
  end

  def get_jurisdictions type
    jurisdiction = has_jurisdiction type
    
    if jurisdiction
      @country.protected_areas_per_designation(jurisdiction)
    else
      []
    end
  end

  def get_wdpa
    iso = params[:iso].upcase

    if iso.size == 2
      ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'").order(:name).first(3)
    else
      ProtectedArea.joins(:countries).where("countries.iso_3 = '#{iso}'").order(:name).first(3)
    end
  end

end
