class HomeController < ApplicationController
  def index
    home_yml = I18n.t('home')

    @total_pas = ProtectedArea.count
    @total_oecms = 9876543 #TODO replace with correct integer

    search_pas = ProtectedArea.all.map{ |pa| {"id": pa.wdpa_id, "name": pa.name} }
    search_oecms = ProtectedArea.last(4).map{ |pa| {"id": pa.wdpa_id, "name": pa.name} } #TODO make this ALL the OECMS
    @search_pas_categories = [
      { name: 'Protected Areas', placeholder: 'Search for a Protected Area', options: search_pas },
      { name: 'OECMs', placeholder: 'Search for an OECM', options: search_oecms }
    ].to_json
    @search_pas_config = { id: 'search-pas' }.to_json

    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_levels = home_yml[:pas][:levels]
    @pas_categories = home_yml[:pas][:categories]

    comfy_themes = Comfy::Cms::Page.find_by_slug("thematical-areas")
    @themes_title = comfy_themes.label
    @themes_url = comfy_themes.full_path
    @themes = comfy_themes.children.published.map{ |page| {
        "label": page.label,
        "url": page.url,
        "intro": "field needs created in the CMS", #TODO create field in CMS
        "image": "field needs created in the CMS" #TODO create field in CMS
      }
    }

    @temp_pas = ProtectedArea.first(4)

    @temp_themes = Comfy::Cms::Page.find_by_slug("equity").children.order(created_at: :desc)

    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @carousel_slides = HomeCarouselSlide.all.select{|slide| slide.published }
  end
end
