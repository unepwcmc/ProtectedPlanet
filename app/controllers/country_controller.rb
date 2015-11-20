class CountryController < ApplicationController
  after_filter :enable_caching
  before_filter :load_vars, :no_footer

  def show
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
    @country = Country.where(iso: params[:iso]).first
    if @country.protected_areas.count > 0
      @random_protected_areas = @country.random_protected_areas 2
    end

    @presenter = StatisticPresenter.new @country
    @designations_by_jurisdiction = @country.designations.group_by { |design|
      design.jurisdiction.name
    }
  end
end
