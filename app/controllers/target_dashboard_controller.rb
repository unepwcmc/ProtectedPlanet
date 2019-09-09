class TargetDashboardController < ApplicationController

  def index
    countries = Country.paginate(per_page: CountrySerializer::PER_PAGE, page: 1)
    @countries = CountrySerializer.new({}, countries).serialize
    @targets = Aichi11TargetSerializer.new.serialize
    @global_stats = Aichi11Target.get_global_stats
    

    ###
    # need to get text into yml files
    ###

    @country_and_regions_headings = [
      {
        id: 'country',
        title: 'Country/Region',
        # tooltip: need to re-think how to do the tooltips as the same ones are all over the page
      },
      {
        id: 'coverage',
        title: 'Coverage'
      },
      {
        id: 'pame',
        title: 'Effectively managed'
      },
      {
        id: 'connected',
        title: 'Well connected'
      },
      {
        id: 'kba',
        title: 'Areas of importance for biodiversity'
      }
    ].to_json


    #   body: [
    #     { 
    #       title: 'France', 
    #       url: 'http://localhost/country/france', 
    #       stats: [
    #         { 
    #           title: 'Coverage',
    #           charts: [
    #             { 
    #               title: 'Terrestrial', value: 55, target: 75, colour: 'terrestrial' 
    #             },
    #             { 
    #               title: 'Marine', value: 55, target: 75, colour: 'marine' 
    #             }
    #           ]
    #         },
    #         { 
    #           title: 'Effectively managed',
    #           charts: [
    #             { 
    #               title: 'Terrestrial', value: 55, target: 75, colour: 'terrestrial' 
    #             },
    #             { 
    #               title: 'Marine', value: 55, target: 75, colour: 'marine' 
    #             }
    #           ]
    #         },
    #         { 
    #           title: 'Well connected',
    #           charts: [
    #             { 
    #               title: 'Global', value: 55, target: 75, colour: 'global' 
    #             }
    #           ]
    #         },
    #         { 
    #           title: 'Areas of importance for biodiversity',
    #           charts: [
    #             { 
    #               title: 'Global', value: 55, target: 75, colour: 'global' 
    #             }
    #           ]
    #         }
    #       ] 
    #     },
    #     {title:'Spain',url:'http://localhost/country/spain',stats:[{title:'Coverage',charts:[{title:'Terrestrial',value:55,target:75,colour:'terrestrial'},{title:'Marine',value:55,target:75,colour:'marine'}]},{title:'Effectivelymanaged',charts:[{title:'Terrestrial',value:55,target:75,colour:'terrestrial'},{title:'Marine',value:55,target:75,colour:'marine'}]},{title:'Wellconnected',charts:[{title:'Global',value:55,target:75,colour:'global'}]},{title:'Areasofimportanceforbiodiversity',charts:[{title:'Global',value:55,target:75,colour:'global'}]}]}
    #   ]
    # }.to_json
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
