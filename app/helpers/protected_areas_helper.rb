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

  def url_for_related_source source, protected_area
    File.join(
      Rails.application.secrets.related_sources_base_urls[source],
      protected_area.wdpa_id.to_s
    )
  end

  def completion_attribute label, complete
    if complete
      content_tag(:li, class: 'complete') do
        icon = content_tag(:i, '', class: 'fa fa-check')
        raw "#{icon} #{label}"
      end
    else
      content_tag(:li, label, class: 'non-complete')
    end
  end

  def parse_management_plan management_plan
    if (management_plan.is_a? String) && (management_plan.starts_with?("http"))
      link_to("View Management Plan", management_plan)
    else
      management_plan
    end
  end
end
