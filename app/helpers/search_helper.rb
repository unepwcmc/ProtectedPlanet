module SearchHelper
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
end
