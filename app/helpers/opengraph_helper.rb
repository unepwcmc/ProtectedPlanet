module OpengraphHelper
  include Comfy::CmsHelper

  # Methods which include a fallback if the requested value is blank
  def og_description
    desc = cms_fragment_content(:summary, @cms_page)
    desc.blank? ? t('meta.site.description') : desc
  end

  def og_image
    image = cms_fragment_render(:hero_image, @cms_page)
    image.blank? ? URI.join(root_url, helpers.image_path(t('meta.image'))) : image
  end

  def og_title
    title = cms_fragment_content(:label, @cms_page)
    title.blank? ? t('meta.site.title') : title
  end
end