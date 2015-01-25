module ProtectedAreasHelper
  def map_bounds protected_area=nil
    return Rails.application.secrets.default_map_bounds unless protected_area

    {
      'from' => protected_area.bounds.first,
      'to' =>   protected_area.bounds.last
    }
  end

  def related_links? protected_area
    !!protected_area.wikipedia_article
  end

  def completion_attribute label, complete
    if complete
      content_tag(:li, class: 'complete') do
        content_tag(:i, "   #{label}", class: 'fa fa-check')
      end
    else
      content_tag(:li, label, class: 'non-complete')
    end
  end
end
