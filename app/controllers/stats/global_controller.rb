class Stats::GlobalController < ApplicationController
  def index
    @region = Region.where(iso: 'GL').first
    @presenter = StatisticPresenter.new @region

    @number_of_pas = ProtectedArea.count
    @pas_with_iucn_category = ProtectedArea.with_valid_iucn_categories.count
    @number_of_designations = Designation.count
    @countries_providing_data = Country.data_providers.count

    @focus = 'world'
  end
end
