class CountryController < ApplicationController
  after_action :enable_caching
  before_action :load_vars, except: [:codes, :compare]

  def show
    @country_presenter = CountryPresenter.new @country

    @flag_path = ActionController::Base.helpers.image_url("flags/#{@country.name.downcase}.svg"),
    @iucn_categories = @country.protected_areas_per_iucn_category
    @governance_types = @country.protected_areas_per_governance

    @sites = [] ##TODO 

    @sources = [
      {
        title: 'Source name',
        date_updated: '2019',
        url: 'http://link-to-source.com'
      }
    ]

    @total_oecm = 0 ##TODO
    @total_pame = @country.protected_areas.with_pame_evaluations.count
    @total_wdpa = @country.protected_areas.count

    
    
    ##TODO need adding
    # protected_national_report: statistic_presenter.percentage_nr_marine_cover, 
    # national_report_version: statistic_presenter.nr_version,

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

  def pas_sample(size=3)
    iso = params[:iso].upcase
    pas = nil

    if iso.size == 2
      pas = ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'")
    else
      pas = ProtectedArea.joins(:countries).where("countries.iso_3 = '#{iso}'")
    end

    pas.order(:name).first(size)
  end

end
