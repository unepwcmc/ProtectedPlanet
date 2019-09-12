class TargetDashboardController < ApplicationController

  def index
    countries = Country.paginate(per_page: CountrySerializer::PER_PAGE, page: 1)
    @countries = CountrySerializer.new({}, countries).serialize
    @targets = Aichi11TargetSerializer.new.serialize
    @global_stats = Aichi11Target.get_global_stats

    @search_config = { id: 'search', placeholder: t('thematic_area.target_11_dashboard.search_config.label') }.to_json

    @search_options = [ #this should be the list of countries and regions,
      {
        id: 'FRA', #TODO @FERDI or whatever you want the ids to be this is what will be sent to the backend (but that can be changed if you need the name as well)
        name: 'France'
      },
      {
        id: 'ESP',
        name: 'Spain'
      }
    ].to_json

    @endpoint = {
      url: '/target-11-dashboard/load-countries',
      params: [
        'target_dashboard[page]=PAGE',
        'target_dashboard[per_page]=PERPAGE',
        'target_dashboard[sort_by]=SORTBY',
        'target_dashboard[order]=ORDER',
        #'target_dashboard[search_term]=SEARCHTERM #TODO @FERDI make this work!
      ]
    }

    @country_and_regions_headings =
      Aichi11TargetDashboardSerializer.new.serialize_head
  end

  def load_countries
    @country_and_regions =
      Aichi11TargetDashboardSerializer.new(target_dashboard_params).to_json

    render json: @country_and_regions
  end

  private

  def target_dashboard_params
    params.require(:target_dashboard).permit(:per_page, :page, :sort_by, :order)
  end
end
