class Stats::RegionalController < ApplicationController
  def show
    iso = params[:iso]

    @region = Region.where(iso: iso).first
    @number_of_pas = Stats::Regional.total_pas iso
    @percentage_of_global_pas = Stats::Regional.percentage_global_pas iso
    @pas_with_iucn_category = Stats::Regional.pas_with_iucn_category iso
    @number_of_designations = Stats::Regional.designation_count iso
    @countries_providing_data = Stats::Regional.countries_providing_data iso
  end
end
