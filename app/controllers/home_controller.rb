class HomeController < ApplicationController
  def index
    @number_of_pas = Stats::Global.pa_count
    @number_of_designations = Stats::Global.designation_count
    @pas_with_iucn_category = Stats::Global.pas_with_iucn_category
    @countries_providing_data = Stats::Global.countries_providing_data
  end
end
