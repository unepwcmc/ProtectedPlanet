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

    link_params = params.merge({
      model.class.to_s.underscore => model.id
    })

    link_to url_for(link_params) do
      facet_count = content_tag(:strong, "(#{facet[:count]})")
      raw "#{model.name} #{facet_count}"
    end
  end

  def clear_filters_link params
    link_to "Clear Filters", search_path(params.slice(:q))
  end
end
