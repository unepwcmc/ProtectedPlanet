class Stats::CountryController < ApplicationController
  def show
    iso = params[:iso]

    @country = ::Country.where(iso: iso).first
    @number_of_pas = Stats::Country.total_pas iso
    @percentage_of_global_pas = Stats::Country.percentage_global_pas iso
    @precision = 2
    @pas_with_iucn_category = Stats::Country.pas_with_iucn_category iso
    @number_of_designations = Stats::Country.designation_count iso
    @designations_by_frequency = Stats::Country.protected_areas_by_designation iso

    # TODO
    @percentage_protected = Random.rand(100)
    @percentage_protected_land = Random.rand(100)
    @percentage_protected_sea = Random.rand(100)
    @percentage_protected_coast = Random.rand(100)
    @focus = 'country'
  end
end
