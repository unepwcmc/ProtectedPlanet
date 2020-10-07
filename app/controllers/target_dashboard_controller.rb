class TargetDashboardController < ApplicationController
  def index
    countries = Country.paginate(per_page: CountrySerializer::PER_PAGE, page: 1)
    @countries = CountrySerializer.new({}, countries).serialize
    @global_stats = Aichi11TargetSerializer.new.serialize

    _options = Aichi11TargetDashboardSerializer.new.serialize_options

    @search = {
      config: { id: 'search', placeholder: t('thematic_area.target_11_dashboard.search_config.label') },
      options: _options
    }.to_json

    @endpoint = {
      url: '/target-11-dashboard/load-countries',
      params: [
        'target_dashboard[page]=PAGE',
        'target_dashboard[per_page]=PERPAGE',
        'target_dashboard[sort_by]=SORTBY',
        'target_dashboard[order]=ORDER',
        'target_dashboard[search_id]=SEARCHID'
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
    params.require(:target_dashboard).permit(:per_page, :page, :sort_by, :order, :search_id)
  end
end
