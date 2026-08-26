module MetadataHelper
  DESCRIPTION_LIMIT = 200

  def page_title
    title = (@page_title.presence || content_for(:page_title).presence).to_s.squish
    brand = t('meta.site.name')

    return "#{t('meta.site.title')} | #{brand}" if title.blank?
    return title if title.include?(brand)

    "#{title} | #{brand}"
  end

  def page_description
    description = (@page_description.presence || t('meta.site.description')).to_s.squish

    description.truncate(DESCRIPTION_LIMIT, separator: ' ')
  end

  def opengraph_title_and_description_with_suffix(suffix)
    opengraph.content('og', title: t('meta.site.name_with_suffix', suffix: suffix), description: t('meta.site.title_with_suffix', suffix: suffix))
  end
end
