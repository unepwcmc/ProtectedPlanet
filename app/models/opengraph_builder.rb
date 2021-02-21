# frozen_string_literal: true

# This class is meant to be used as a wrapper for
# Opengraph meta-tags within HTML markup.
#
class OpengraphBuilder
  attr_accessor :data

  # The initializer accepts a hash with the starting structure for example...
  #
  # og = OpengraphBuilder.new(
  #   { og: { title: 'my title' }, twitter: { card: 'my_card' } }
  # )
  def initialize(content = {})
    @data = Hash.new({}).merge(content.deep_stringify_keys)
  end

  # Use og.content with a prefix and hash to store, for example...
  #
  # og 'twitter', card: 'content',
  #               title: 'Example title!',
  #               description: 'Example description',
  #               site: '@example',
  #               image: 'https://placehold.it/100',
  #               creator: '@example' %>
  #
  # To load this content into a layout view, you would then simply call...
  #
  # <%== og.content %> to get all of the content in the store, or...
  # <%== og %> as it has a to_s method, or...
  #
  # <%== og.content('twitter') %> to get only the content for a specific prefix.
  #
  def content(prefix = nil, options = nil)
    if options.nil?
      html(prefix)
    else
      save_options_at_prefix(prefix ? prefix.to_s : 'og', options)
    end
  end

  def to_s
    html
  end

  private

  def html(prefix = nil)
    return meta_tags(@data[prefix], prefix) if prefix

    arr = []
    @data.each { |p, data| arr << meta_tags(data, p) }
    arr.join("\n")
  end

  def save_options_at_prefix(prefix, options)
    @data[prefix.to_s].merge!(options.deep_stringify_keys)
  end

  def meta_tags(data, prefix)
    arr = []
    data.each do |key, value|
      arr << format(
        '<meta property="%<prefix>s:%<key>s" content="%<value>s">',
        { prefix: prefix, key: key, value: value.to_s }
      )
    end
    arr.join("\n")
  end
end
