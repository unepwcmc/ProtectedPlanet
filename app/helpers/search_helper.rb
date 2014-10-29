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

    link_to link_name, search_path(link_params)
  end

  def protected_area_cover protected_area, opts={size: {x: 256, y: 128}}
    cover_url = if protected_area.images.any?
      protected_area.images.first.url
    else
      mapbox_url protected_area.geojson, opts[:size]
    end

    image_tag cover_url, style: "width: #{opts[:size][:x]}px; height: #{opts[:size][:y]}px", alt: protected_area.name
  end

  def country_cover country, opts={size: {x: 256, y: 128}}
    image_tag(
      "countries/#{country.iso}.png",
      style: "width: #{opts[:size][:x]}px; height: #{opts[:size][:y]}px",
      alt: country.name
    )
  end

  def region_cover region, opts={size: {x: 256, y: 128}}
    image_tag(
      "regions/#{region.iso}.png",
      style: "width: #{opts[:size][:x]}px; height: #{opts[:size][:y]}px",
      alt: region.name
    )
  end
end
