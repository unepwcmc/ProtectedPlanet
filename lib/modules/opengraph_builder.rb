# frozen_string_literal: true

# This class is meant to be used as a wrapper for
# Opengraph meta-tags within HTML markup.
#
class OpengraphBuilder
  attr_accessor :data

  # Create an instance e.g. og = OpengraphBuilder.new

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
  #
  # <%== og.content('twitter') %> to get only the content for a specific prefix.
  #
  def content(prefix = nil, **options)
    if options.empty?
      return meta_tags(@data[prefix], prefix) if prefix

      arr = []
      @data.each { |p, data| arr << meta_tags(data, p) }
      arr.join("\n")
    else
      prefix = prefix ? prefix.to_s : 'og'
      @data[prefix] = @data[prefix].merge(options.deep_stringify_keys)
    end
  end

  private

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