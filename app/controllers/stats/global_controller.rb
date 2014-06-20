class Stats::GlobalController < ApplicationController
  def index
    @number_of_pas = Stats::Global.pa_count
    @pas_with_iucn_category = Stats::Global.pas_with_iucn_category
    @number_of_designations = Stats::Global.designation_count
    @countries_providing_data = Stats::Global.countries_providing_data
    @territory_covered_by_pas = Stats::Global.percentage_cover_pas || 0
  end
end