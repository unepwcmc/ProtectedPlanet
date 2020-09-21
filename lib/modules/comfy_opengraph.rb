# frozen_string_literal: true

# Helper class to set Opengraph meta-tags for use with Comfy CMS @cms_page's
class ComfyOpengraph
  include Rails.application.routes.url_helpers
  include Comfy::CmsHelper

  attr_accessor :mappings

  # Set the fragment to Opengraph key mappings for example:
  # comfyOpengraph = ComfyOpengraph.new({
  #   'social-title': 'title',
  #   'social-description': 'description',
  #   'theme_image': 'image'
  # })
  def initialize(mappings, page:)
    throw 'Mappings must be in hash format.' unless mappings.is_a?(Hash)
    @mappings = mappings.deep_stringify_keys
    @page = page
  end

  # Iterate over the fragments of a CMS page and set their Opengraph values
  def parse(opengraph: nil, type: 'og')
    @page.fragments.to_a.each do |fragment|
      id = fragment.identifier.to_s
      next unless @mappings.key?(id)

      value = get_fragment_value(fragment)
      next if value.blank? # don't use the value if it isn't set

      # set opengraph meta-tag via a new hash
      payload = {}
      payload[@mappings[id]] = value
      opengraph.content(type, payload)
    end
  end

  private

  def get_fragment_value(fragment)
    if fragment.tag =~ /file/ && fragment.attachments.first # get path when fragment is file
      Rails.env.development? ? local_url(fragment) : production_url(fragment)
    else 
      process_meta_tags(fragment)
    end
  end

  def local_url(fragment)
    URI.join(root_url, rails_blob_path(fragment.attachments.first.blob, only_path: true))
  end

  def production_url(fragment)
    fragment.attachments.first.service_url&.split('?')&.first
  end

  def process_meta_tags(fragment)
    identifier = fragment.identifier
    
    case identifier
    when 'social-title'
      return og_title
    when 'social-description'
      return og_description
    when 'image'
      return og_image
    else
      # expect a string by default
      fragment.content&.squish
    end
  end

  def og_description
    social_desc = cms_fragment_content(:social_description, @page)
    summary = cms_fragment_content(:summary, @page)
    fallback_summary = summary.blank? ? I18n.t('meta.site.description') : summary
    social_desc.blank? ? fallback_summary : social_desc
  end

  def og_image
    image = cms_fragment_content(:image, @page).try(:attachments)&.first
    path_to_image = URI.join(root_url, url_for(image))
    fallback_image = URI.join(root_url, image_path(I18n.t('meta.image')))
    image.blank? ? fallback_image : path_to_image
  end

  def og_title
    social_title = cms_fragment_content(:social_title, @page)
    title = @page.label
    fallback_title = title.blank? ? I18n.t('meta.site.title') : title
    social_title.blank? ? fallback_title : social_title
  end
end
