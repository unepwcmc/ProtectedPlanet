module SearchHelper
  include ApplicationHelper

  def type_li_tag type, current_type
    selected_class = (type == current_type) ? "selected" : ""

    content_tag(:li, class: selected_class) do
      yield
    end
  end

  def facet_link facet
    model = facet[:model]

    link_name = "#{model.name} (#{facet[:count]})"
    link_params = params.merge({
      model.class.to_s.underscore => model.id
    })

    link_to search_path(link_params) do
      facet_count = content_tag(:strong, "(#{facet[:count]})")
      raw "#{model.name} #{facet_count}"
    end
  end

  def protected_area_cover protected_area, opts={size: {x: 256, y: 128}}
    image_tag(
      tiles_path({id: protected_area.id}.merge(opts)),
      style: style(opts),
      alt: protected_area.name
    )
  end

  def country_cover country, opts={size: {x: 256, y: 128}}
    image_tag("countries/#{country.iso}.png", style: style(opts), alt: country.name)
  end

  def region_cover region, opts={size: {x: 256, y: 128}}
    image_tag("regions/#{region.iso}.png", style: style(opts), alt: region.name)
  end

  private

  def style opts
    "width: #{opts[:size][:x]}px; height: #{opts[:size][:y]}px"
  end
end
