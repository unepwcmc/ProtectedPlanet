# frozen_string_literal: true

# Helper class to set Opengraph meta-tags for use with Comfy CMS @cms_page's
class ComfyOpengraph
  include Rails.application.routes.url_helpers

  attr_accessor :mappings

  # Set the fragment to Opengraph key mappings for example:
  # comfyOpengraph = ComfyOpengraph.new({
  #   'social-title': 'title',
  #   'social-description': 'description',
  #   'theme_image': 'image'
  # })
  def initialize(mappings)
    throw 'Mappings must be in hash format.' unless mappings.is_a?(Hash)
    @mappings = mappings.deep_stringify_keys
  end

  # Iterate over the fragments of a CMS page and set their Opengraph values
  def parse(opengraph: nil, page: nil)
    page.fragments.to_a.each do |fragment|
      id = fragment.identifier.to_s
      next unless @mappings.key?(id)

      value = get_fragment_value(fragment)
      next if value.blank? # don't use the value if it isn't set

      # set opengraph meta-tag via a new hash
      payload = {}
      payload[@mappings[id]] = value
      opengraph.content('og', payload)
    end
  end

  private

  def get_fragment_value(fragment)
    if fragment.tag =~ /file/ && fragment.attachments.first # get path when fragment is file
      if Rails.env.development?
        URI.join(root_url, rails_blob_path(fragment.attachments.first.blob, only_path: true))
      else
        fragment.attachments.first.service_url&.split('?')&.first
      end
    else # expect a string by default
      fragment.content&.squish
    end
  end
end
