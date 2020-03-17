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
    
    @pas_categories = home_yml[:pas][:categories].map{ |category| {
        image: '', ##cms_fragment_render(:theme_image, Comfy::Cms::Page.find_by_slug(category[:slug])), ##TODO FERDI can you get image here?
        title: category[:title],
        url: 'filtered wdpa page' ##TODO filtered WDPA results page 
      }
    }

    comfy_themes = Comfy::Cms::Page.find_by_slug("thematical-areas")
    @themes_title = comfy_themes.label
    @themes_url = comfy_themes.full_path

    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @carousel_slides = HomeCarouselSlide.all.select{|slide| slide.published }
  end
end