module HomeHelper
  def pas_categories
    home_yml = I18n.t('home')

    home_yml[:pas][:categories].map do |category|
      #Make sure to remove any leading /
      slug = category[:slug].split('/').last
      filter = Array.wrap(category[:filter])
      cms_page = Comfy::Cms::Page.find_by_slug(slug)
      {
        image: cms_fragment_render(:theme_image, cms_page),
        title: category[:title],
        url: search_areas_path(db_type: 'wdpa', filters: {is_type: filter })
      }
    end
  end

end
