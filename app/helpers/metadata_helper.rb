module MetadataHelper
  def page_title
    page_title = content_for(:page_title)
    site_title = t('meta.site.title')
    if page_title
      "#{page_title} | #{site_title}".html_safe
    else
      site_title
    end
  end

  def opengraph_title_and_description_with_suffix(suffix)
    opengraph.content('og',
                      title: t('meta.site.name_with_suffix', suffix: suffix),
                      description: t('meta.site.title_with_suffix', suffix: suffix))
  end
end
