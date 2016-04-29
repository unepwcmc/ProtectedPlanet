class CountryController < ApplicationController
  after_filter :enable_caching
  before_filter :load_vars, except: [:codes]

  def show
    respond_to do |format|
      format.html
      format.pdf {
        rasterizer = Rails.root.join("vendor/assets/javascripts/rasterize.js")
        url = url_for(action: :show, iso: @country.iso, for_pdf: true)
        dest_pdf = Rails.root.join("tmp/#{@country.iso}-country.pdf").to_s

        `phantomjs #{rasterizer} '#{url}' #{dest_pdf} A4`
        send_file dest_pdf, type: 'application/pdf'
      }
    end
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
    params[:iso_to_compare] ? load_second_country : load_comparable_countries
  end

  private

  def load_second_country
    @second_country = Country.where(iso: params[:iso_to_compare]).first
    @second_presenter = StatisticPresenter.new @second_country
  end

  def load_comparable_countries
    @comparable_countries = Country.select(:iso, :name).all
  end

  def load_vars
    @country = if params[:iso].size == 2
      Country.where(iso: params[:iso]).first
    else
      Country.where(iso_3: params[:iso]).first
    end

    @presenter = StatisticPresenter.new @country
    @pame_statistics = @country.pame_statistic
    @designations_by_jurisdiction = @country.designations.group_by { |design|
      design.jurisdiction.name rescue "Not Reported"
    }
  end
end
