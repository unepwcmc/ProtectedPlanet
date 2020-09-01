module HomeHelper
  def pas_categories
    home_yml = I18n.t('home')

    home_yml[:pas][:categories].map do |category|
      #Make sure to remove any leading /
      slug = category[:slug].split('/').last
      cms_page = Comfy::Cms::Page.find_by_slug(slug)
      {
        image: cms_fragment_render(:image, cms_page),
        title: category[:title],
        url: search_areas_path(filters: get_filters(category[:filter]))
      }
    end
  end

  def get_filters(filter)
    if filter == 'is_green_list'
      { special_status: [filter] }
    else
      { is_type: [filter] }
    end.merge(db_type: ['wdpa'])
  end
end
