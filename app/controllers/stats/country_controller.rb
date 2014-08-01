class Stats::CountryController < ApplicationController
  def show
    @country = Country.where(iso: params[:iso]).first

    @country_statistic = @country.country_statistic
    global_statistic = Region.where(iso: 'GL').first.regional_statistic

    @number_of_pas = @country.protected_areas.count
    @precision = 2

    @percentage_of_global_pas = (@country_statistic.pa_area / global_statistic.pa_area) * 100
    @pas_with_iucn_category = @country.protected_areas_with_iucn_categories.count
    @number_of_designations = @country.designations.count

    @percentage_protected = @country_statistic.percentage_pa_cover
    @percentage_protected_land = @country_statistic.percentage_pa_land_cover
    @percentage_protected_sea = @country_statistic.percentage_pa_eez_cover
    @percentage_protected_coast = @country_statistic.percentage_pa_ts_cover
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
