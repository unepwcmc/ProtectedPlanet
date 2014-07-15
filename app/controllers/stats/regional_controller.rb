class Stats::RegionalController < ApplicationController
  def show
    iso = params[:iso]

    @region = Region.where(iso: iso).first
    @number_of_pas = Stats::Regional.total_pas iso
    @precision = 0
    @percentage_of_global_pas = Stats::Regional.percentage_global_pas iso
    @pas_with_iucn_category = Stats::Regional.pas_with_iucn_category iso
    @number_of_designations = Stats::Regional.designation_count iso
    @countries_providing_data = Stats::Regional.countries_providing_data iso

    # TODO
    @percentage_protected = Random.rand(100)
    @percentage_protected_land = 50
    @percentage_protected_sea = Random.rand(100)
    @percentage_protected_coast = Random.rand(100)
    @focus = 'region'
  end
end
