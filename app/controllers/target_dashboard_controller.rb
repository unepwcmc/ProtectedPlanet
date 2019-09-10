class TargetDashboardController < ApplicationController

  def index
    countries = Country.paginate(per_page: CountrySerializer::PER_PAGE, page: 1)
    @countries = CountrySerializer.new({}, countries).serialize
    @targets = Aichi11TargetSerializer.new.serialize
    @global_stats = Aichi11Target.get_global_stats


    ###
    # need to get text into yml files
    ###

    @country_and_regions = Aichi11TargetDashboardSerializer.new.serialize[:data].to_json
  end

  def load_countries
    @country_and_regions =
      Aichi11TargetDashboardSerializer.new(target_dashboard_params).serialize[:data].to_json

    render json: @country_and_regions
  end

  private

  def target_dashboard_params
    params.require(:target_dashboard).permit(:per_page, :page, :sort_by, :order)
  end
end
