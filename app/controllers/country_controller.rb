class CountryController < ApplicationController
  after_filter :enable_caching
  before_filter :load_vars, except: [:codes]

  def show
    respond_to do |format|
      format.html
      format.pdf {
        options = {format: 'A4', margin: '0cm'}
        pdf_generator = PhantomPDF::Generator.new(
          url_for(action: :show, iso: @country.iso, for_pdf: true),
          Rails.root.join("tmp/#{@country.iso}-country.pdf").to_s,
          options
        )
        send_file pdf_generator.generate, type: 'application/pdf'
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

    if @country.protected_areas.count > 0
      @random_protected_areas = @country.random_protected_areas 2
    end

    @presenter = StatisticPresenter.new @country
    @designations_by_jurisdiction = @country.designations.group_by { |design|
      design.jurisdiction.name
    }
  end
end
