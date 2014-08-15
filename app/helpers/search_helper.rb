module SearchHelper
  def type_li_tag type, current_type
    selected_class = (type == current_type) ? "selected" : ""

    content_tag(:li, class: selected_class) do
      yield
    end
  end
end
