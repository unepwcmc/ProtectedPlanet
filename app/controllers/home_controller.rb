class HomeController < ApplicationController
  def index
    home_yml = I18n.t('home')

    @pa_coverage_percentage = 9999 #TODO Total PA coverage in %

    @search_area_types = [
      { id: 'wdpa', title: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.search-wdpa') },
      { id: 'oecm', title: I18n.t('global.area-types.oecm'), placeholder: I18n.t('global.placeholder.search-oecms') }
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