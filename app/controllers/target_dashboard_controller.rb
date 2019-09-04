class TargetDashboardController < ApplicationController

  def index
    countries = Country.paginate(per_page: CountrySerializer::PER_PAGE, page: 1)
    @countries = CountrySerializer.new({}, countries).serialize
    @targets = Aichi11TargetSerializer.new.serialize
    global_land_cover = CountryStatistic.global_percentage_pa_land_cover
    global_marine_cover = CountryStatistic.global_percentage_pa_marine_cover
    global_pame_land_cover = PameStatistic.global_pame_percentage_pa_land_cover
    global_pame_marine_cover = PameStatistic.global_pame_percentage_pa_marine_cover

    @global_stats = [
      {
        title: 'Coverage',
        charts: [
          {
            title: 'Terrestrial',
            colour: 'terrestrial',
            value: global_land_cover,
            target: 80 #TODO
          },
          {
            title: 'Marine',
            colour: 'marine',
            value: global_marine_cover,
            target: 80 #TODO
          }
        ]
      },
      {
        title: 'Effectively managed',
        charts: [
          {
            title: 'Terrestrial',
            colour: 'terrestrial',
            value: global_pame_land_cover,
            target: 80 #TODO
          },
          {
            title: 'Marine',
            colour: 'marine',
            value: global_pame_marine_cover,
            target: 80 #TODO
          }
        ]
      }
    ]
  end

  def load
    @countries = CountrySerializer.new(target_dashboard_params).serialize

    render json: @countries
  end

  private

  def target_dashboard_params
    params.require(:target_dashboard).permit(:per_page, :page, :sort_by, :order)
  end
end
