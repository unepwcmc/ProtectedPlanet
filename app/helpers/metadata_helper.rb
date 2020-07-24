module MetadataHelper
  def page_title
    page_title = content_for(:page_title)
    site_title = t('seo.defaults.site_title')
    if page_title
      "#{page_title} | #{site_title}".html_safe
    else
      site_title
    end
  end
end
