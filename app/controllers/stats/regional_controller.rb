class Stats::RegionalController < ApplicationController
  def show
    iso = params[:iso]

    @region = Region.where(iso: iso).first
    @number_of_pas = @region.protected_areas.count

    @regional_statistic = @region.regional_statistic
    global_statistic = Region.where(iso: 'GL').first.regional_statistic

    @precision = 0
    @percentage_of_global_pas = (@regional_statistic.pa_area / global_statistic.pa_area) * 100
    @pas_with_iucn_category = @region.protected_areas_with_iucn_categories.count
    @number_of_designations = @region.designations.count
    @countries_providing_data = @region.countries_providing_data.count

    @percentage_protected = @regional_statistic.percentage_pa_cover
    @percentage_protected_land = @regional_statistic.percentage_pa_land_cover
    @percentage_protected_sea = @regional_statistic.percentage_pa_eez_cover
    @percentage_protected_coast = @regional_statistic.percentage_pa_ts_cover
    @focus = 'region'
  end

  private

  def get_stats method, iso, round
    value = Stats::Regional.send(method.to_sym, iso)
    if value && round
      value.round
    elsif value
      value
    else
      nil
    end
  end
end
