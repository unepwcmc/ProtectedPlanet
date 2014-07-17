class Stats::RegionalController < ApplicationController
  def show
    iso = params[:iso]

    @region = Region.where(iso:iso).first
    @number_of_pas = Stats::Regional.total_pas iso
    @precision = 0
    @percentage_of_global_pas = get_stats 'percentage_global_pas', iso
    @pas_with_iucn_category = get_stats 'pas_with_iucn_category', iso
    @number_of_designations = get_stats 'designation_count', iso
    @countries_providing_data = get_stats 'countries_providing_data', iso

    @percentage_protected = get_stats 'percentage_pa_cover', iso
    @percentage_protected_land = get_stats 'percentage_protected_land', iso
    @percentage_protected_sea = get_stats 'percentage_protected_sea', iso
    @percentage_protected_coast = get_stats 'percentage_protected_coast', iso
    @focus = 'region'
  end

  private

  def get_stats method, iso
    value = Stats::Regional.send(method.to_sym, iso)
    if value then value.round else 'Not applicable' end
  end
end
