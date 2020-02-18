class HomeController < ApplicationController
  def index
    home_yml = I18n.t('home')

    @total_pas = ProtectedArea.count
    @total_oecms = 9876543 

    @search_area_types = [
      { name: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.wdpa') },
      { name: I18n.t('global.area-types.oecm'), placeholder: I18n.t('global.placeholder.oecm') }
    ].to_json

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