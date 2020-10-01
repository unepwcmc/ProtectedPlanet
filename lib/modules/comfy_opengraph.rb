# frozen_string_literal: true
require 'mini_magick'

# Helper class to set Opengraph meta-tags for use with Comfy CMS @cms_page's
class ComfyOpengraph
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::AssetUrlHelper
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

      value = process_meta_tags(fragment)
      next if value.blank? # don't use the value if it isn't set

      # set opengraph meta-tag via a new hash
      payload = {}
      payload[@mappings[id]] = value
      opengraph.content(type, payload)
    end
  end

  private

  def local_url(image)
    URI.join(root_url, rails_blob_path(image.blob, only_path: true))
  end

  def production_url(image)
    image.service_url&.split('?')&.first
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
    image = Comfy::Cms::Fragment.find_by(identifier: 'image').attachments.first
    fallback_image = URI.join(root_url, image_path(I18n.t('meta.image')))
    image.blank? ? fallback_image : resize(image)
  end

  def resize(image)
    #TODO - Get this working as we don't want to resize unnecessarily
    # Using FastImage as MiniMagick is way too slow
    # actual_image = MiniMagick::Image.open(local_url(image))

    # # Return if image dimensions are sufficient
    # if actual_image.height <= 4096 && actual_image.width <= 4096
    #   return Rails.env.development? ? local_url(image) : production_url(image)
    # end

    # In line with Twitter guidelines for maximum dimensions
    # IMPORTANT: takes an ActiveStorage attachment rather than a relative path to the image 
    variant = image.variant(size: '4096x4096')
    URI.join(root_url, rails_representation_path(variant, only_path: true))
  end

  def og_title
    social_title = cms_fragment_content(:social_title, @page)
    title = @page.label
    fallback_title = title.blank? ? I18n.t('meta.site.title') : title
    social_title.blank? ? fallback_title : social_title
  end
end
