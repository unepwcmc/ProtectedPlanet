class TargetDashboardController < ApplicationController

  def index
    countries = Country.paginate(per_page: CountrySerializer::PER_PAGE, page: 1)
    @countries = CountrySerializer.new({}, countries).serialize
    @targets = Aichi11TargetSerializer.new.serialize
    @global_stats = Aichi11Target.get_global_stats
    
    @row = #[
      { 
        title: 'France', 
        url: 'http://localhost/country/france', 
        stats: [
          { 
            title: 'Coverage',
            charts: [
              { 
                title: 'Terrestrial', value: 55, target: 75, colour: 'terrestrial' 
              },
              { 
                title: 'Marine', value: 55, target: 75, colour: 'marine' 
              }
            ]
          },
          { 
            title: 'Effectively managed',
            charts: [
              { 
                title: 'Terrestrial', value: 55, target: 75, colour: 'terrestrial' 
              },
              { 
                title: 'Marine', value: 55, target: 75, colour: 'marine' 
              }
            ]
          },
          { 
            title: 'Well connected',
            charts: [
              { 
                title: 'Global', value: 55, target: 75, colour: 'global' 
              }
            ]
          },
          { 
            title: 'Areas of importance for biodiversity',
            charts: [
              { 
                title: 'Global', value: 55, target: 75, colour: 'global' 
              }
            ]
          }
        ] 
      }.to_json
    # ]
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
