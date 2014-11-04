class Stats::CountryController < ApplicationController
  def show
    @country = Country.where(iso: params[:iso]).first
    @presenter = StatisticPresenter.new @country

    @number_of_pas = @country.protected_areas.count
    @pas_with_iucn_category = @country.protected_areas_with_iucn_categories.count
    @number_of_designations = @country.designations.count
  end

  def new_comparison
    @country = Country.where(iso: params[:iso]).first
    @presenter = StatisticPresenter.new @country
  end

  def compare
    @country = Country.where(iso: params[:iso]).first
    @presenter = StatisticPresenter.new @country

    @comparison_country = Country.where(iso: params[:compare_iso]).first
    @comparison_presenter = StatisticPresenter.new @comparison_country
  end
end
