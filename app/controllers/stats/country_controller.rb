class Stats::CountryController < ApplicationController
  def show
    iso = params[:iso]

    @country = ::Country.where(iso:iso).first
    @number_of_pas = Stats::Country.total_pas iso
    @percentage_of_global_pas = get_stats 'percentage_global_pas', iso
    @precision = 2
    @pas_with_iucn_category = get_stats 'pas_with_iucn_category', iso
    @number_of_designations = get_stats 'designation_count', iso
    @designations_by_frequency = Stats::Country.protected_areas_by_designation iso

    @percentage_protected = get_stats 'percentage_pa_cover', iso
    @percentage_protected_land = get_stats 'percentage_protected_land', iso
    @percentage_protected_sea = get_stats 'percentage_protected_sea', iso
    @percentage_protected_coast = get_stats 'percentage_protected_coast', iso
    @focus = 'country'
  end

  private

  def get_stats method, iso
    value = Stats::Country.send(method.to_sym, iso)
    if value then value.round else 'Not applicable' end
  end
end
