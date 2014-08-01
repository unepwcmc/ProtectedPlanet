class Stats::GlobalController < ApplicationController
  def index
    @number_of_pas = ProtectedArea.count
    @pas_with_iucn_category = ProtectedArea.with_valid_iucn_categories.count
    @number_of_designations = Designation.count
    @countries_providing_data = Country.data_providers.count
    @percentage_of_global_pas = 100

    @global_statistic = Region.where(iso: 'GL').first.regional_statistic
    @percentage_protected = @global_statistic.percentage_pa_cover
    @percentage_protected_land = @global_statistic.percentage_pa_land_cover
    @percentage_protected_sea = @global_statistic.percentage_pa_eez_cover
    @percentage_protected_coast = @global_statistic.percentage_pa_ts_cover
  end
end
