class RegionController < ApplicationController
  before_filter :load_vars

  def show
    region_hash = {
      eez_area: 0,
      ts_area: 0,
      pa_land_area: 0,
      pa_marine_area: 0,
      percentage_pa_land_cover: 0,
      percentage_pa_eez_cover: 0,
      percentage_pa_ts_cover: 0,
      land_area: 0,
      percentage_pa_cover: 0,
      pa_eez_area: 0,
      pa_ts_area: 0,
      percentage_pa_marine_cover: 0,
      marine_area: 0,
      polygons_count: 0,
      points_count: 0
    }

    Country.joins(:region).where(region_id: @region.id).each do |country|
      region_hash[:eez_area] += country.statistic.eez_area || 0
      region_hash[:ts_area] += country.statistic.ts_area || 0
      region_hash[:pa_land_area] += country.statistic.pa_land_area || 0
      region_hash[:pa_marine_area] += country.statistic.pa_marine_area || 0
      region_hash[:percentage_pa_land_cover] += country.statistic.percentage_pa_land_cover || 0
      region_hash[:percentage_pa_eez_cover] += country.statistic.percentage_pa_eez_cover || 0
      region_hash[:percentage_pa_ts_cover] += country.statistic.percentage_pa_ts_cover || 0
      region_hash[:land_area] += country.statistic.land_area || 0
      region_hash[:percentage_pa_cover] += country.statistic.percentage_pa_cover || 0
      region_hash[:pa_eez_area] += country.statistic.pa_eez_area || 0
      region_hash[:pa_ts_area] += country.statistic.pa_ts_area || 0
      region_hash[:percentage_pa_marine_cover] += country.statistic.percentage_pa_marine_cover || 0
      region_hash[:marine_area] += country.statistic.marine_area || 0
      region_hash[:polygons_count] += country.statistic.polygons_count || 0
      region_hash[:points_count] += country.statistic.points_count || 0
    end

    total_points_polygons = region_hash[:polygons_count] + region_hash[:points_count]

    region_hash[:geometry_ratio_polygons] = (((region_hash[:polygons_count]/total_points_polygons.to_f)*100).round rescue 0)
    region_hash[:geometry_ratio_points] = (((region_hash[:points_count]/total_points_polygons.to_f)*100).round   rescue 0)

    @stats = region_hash

  end

  private

  def load_vars
    @region = Region.where(iso: params[:iso].upcase).first

    @region or raise_404

    @presenter = StatisticPresenter.new @region
  end

end
