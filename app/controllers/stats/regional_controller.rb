class Stats::RegionalController < ApplicationController
  def show
    @region = Region.where(iso: params[:iso]).first
    @presenter = StatisticPresenter.new @region

    @number_of_pas = @region.protected_areas.count
    @pas_with_iucn_category = @region.protected_areas_with_iucn_categories.count
    @number_of_designations = @region.designations.count
    @countries_providing_data = @region.countries_providing_data.count

    @focus = 'region'
  end
end
