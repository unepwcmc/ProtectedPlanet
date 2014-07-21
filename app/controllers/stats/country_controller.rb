class Stats::CountryController < ApplicationController
  def show
    iso = params[:iso]

    @country = ::Country.where(iso:iso).first
    @number_of_pas = Stats::Country.total_pas iso
    @percentage_of_global_pas = get_stats 'percentage_global_pas_area', iso, false
    @precision = 2
    @pas_with_iucn_category = get_stats 'pas_with_iucn_category', iso, true
    @number_of_designations = get_stats 'designation_count', iso, true
    @designations_by_frequency = Stats::Country.protected_areas_by_designation iso

    @percentage_protected = get_stats 'percentage_pa_cover', iso, true
    @percentage_protected_land = get_stats 'percentage_protected_land', iso, true
    @percentage_protected_sea = get_stats 'percentage_protected_sea', iso, true
    @percentage_protected_coast = get_stats 'percentage_protected_coast', iso, true
    @focus = 'country'
  end

  private

  def get_stats method, iso, round
    value = Stats::Country.send(method.to_sym, iso)
    if value && round
      value.round
    elsif value
      value
    else
      nil
    end
  end
end
