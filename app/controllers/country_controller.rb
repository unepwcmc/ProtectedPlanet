class CountryController < ApplicationController
  before_filter :load_vars
  before_filter :load_user_projects

  def show
  end

  def compare
    params[:iso2] ? load_second_country : load_comparable_countries
  end

  private

  def load_second_country
    @second_country = Country.where(iso: params[:iso2]).first
    @second_presenter = StatisticPresenter.new @second_country
  end

  def load_comparable_countries
    @comparable_countries = Country.select(:iso, :name).all
  end

  def load_vars
    @country = Country.where(iso: params[:iso]).first
    @presenter = StatisticPresenter.new @country
  end
end
