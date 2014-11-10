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
end
