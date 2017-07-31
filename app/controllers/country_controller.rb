class CountryController < ApplicationController
  after_filter :enable_caching
  before_filter :load_vars, except: [:codes, :compare]

  def show
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

    @presenter = StatisticPresenter.new @country
    @pame_statistics = @country.pame_statistic
    @designations_by_jurisdiction = @country.designations.group_by { |design|
      design.jurisdiction.name rescue "Not Reported"
    }
  end
end
