class TargetDashboardController < ApplicationController

  def index
    countries = Country.paginate(per_page: 8, page: 1)
    @countries = CountrySerializer.new(countries).serialize
    @global_land_cover = CountryStatistic.global_percentage_pa_land_cover
    @global_marine_cover = CountryStatistic.global_percentage_pa_marine_cover
    @global_pame_land_cover = PameStatistic.global_pame_percentage_pa_land_cover
    @global_pame_marine_cover = PameStatistic.global_pame_percentage_pa_marine_cover
  end

  def load
    per_page, page = [
      target_dashboard_params[:per_page],
      target_dashboard_params[:page]
    ]
    countries = Country.paginate(per_page: per_page, page: page)
    @countries = CountrySerializer.new(countries).serialize

    render json: @countries
  end

  private

  def target_dashboard_params
    params.require(:target_dashboard).permit(:per_page, :page)
  end
end
