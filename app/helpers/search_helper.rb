module SearchHelper
  include ApplicationHelper

  def type_li_tag type, current_type
    selected_class = (type == current_type) ? "selected" : ""

    content_tag(:li, class: selected_class) do
      yield
    end
  end

  def facet_link facet
    link_params = params.merge({
       facet[:query] => facet[:identifier]
    })

    link_to url_for(link_params) do
      facet_count = content_tag(:strong, "(#{facet[:count]})")
      raw "#{facet[:label]} #{facet_count}"
    end
  end

  def autocomplete_link result
    if result[:type] == 'protected_area'
      link_to protected_area_url(result[:identifier]) do
        image = image_tag(AssetGenerator.link_to(result[:identifier]))
        raw "#{image}#{result[:name]}"
      end
    else
      link_to country_url(result[:identifier]) do
        image = image_tag("search-placeholder-country.png")
        raw "#{image}#{result[:name]}"
      end
    end
  end

  def clear_filters_link params
    if params.length > 3
      link_to "Clear Filters", search_path(params.slice(:q))
    else
      ''
    end
  end
end
