module OpengraphHelper
  include Comfy::CmsHelper

  # Methods which include a fallback if the requested value is blank
  def og_description
    social_desc = cms_fragment_content(:social_description, @cms_page)
    summary = cms_fragment_content(:summary, @cms_page)
    fallback_summary = summary.blank? ? t('meta.site.description') : summary
    social_desc.blank? ? fallback_summary : social_desc
  end

  def og_image
    image = helpers.url_for(cms_fragment_content(:image, @cms_page).attachments.first)
    image.blank? ? URI.join(root_url, helpers.image_path(t('meta.image'))) : image
  end

  def og_title
    social_title = cms_fragment_content(:social_title, @cms_page)
    title = @cms_page.label
    fallback_title = title.blank? ? t('meta.site.title') : title
    social_title.blank? ? fallback_title : social_title
  end
end