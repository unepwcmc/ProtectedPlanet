module HomeHelper
  def pas_categories
    home_yml = I18n.t('home')

    home_yml[:pas][:categories].map do |category|
      #Make sure to remove any leading /
      slug = category[:slug].split('/').last
      cms_page = Comfy::Cms::Page.find_by_slug(slug)
      {
        image: cms_fragment_render(:theme_image, cms_page),
        title: category[:title],
        url: 'filtered wdpa page' ##TODO filtered WDPA results page 
      }
    end
  end
end
