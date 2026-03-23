module HomeHelper
  def pas_categories
    home_yml = I18n.t('home')

    home_yml[:pas][:categories].map do |category| 
      if(category[:slug] != nil)
        #Make sure to remove any leading /
        slug = category[:slug].split('/').last
        cms_page = Comfy::Cms::Page.find_by_slug(slug)
        image = cms_fragment_render(:image, cms_page)
      else
        image = image_path 'terrestrial.jpg' # this is only here until the terrestrial page is built
      end
      is_green_list = category[:filter] == 'pa_or_any_its_parcels_is_greenlisted'
      {
        image: image,
        title: category[:title],
        url: search_areas_path(filters: SearchAreaLinkFilters.home_category_filters(filter: category[:filter], is_green_list: is_green_list))
      }
    end
  end
end
