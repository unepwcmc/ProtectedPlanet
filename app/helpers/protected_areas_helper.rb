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

  def reported_area
    area = @protected_area.reported_area
    area.try(:nonzero?) ? "#{area.round(2)} km&sup2;".html_safe : "Not Reported"
  end

  def pame_evaluations_summary
    grouped_evaluations = @protected_area.pame_evaluations.group_by(&:methodology)
    grouped_evaluations.update(grouped_evaluations) do |_, evaluations|
      evaluations.map { |ev| ev.year == 0 ? 'Not Reported' : ev.year }
    end
  end


  def has_pame_statistics_for(presenter, area=:land)
    # Ensures pame stats are returned only for Country pages / Statistic presenters
    presenter.class == StatisticPresenter && presenter.pame_statistic &&
      presenter.pame_statistic.send("pame_percentage_pa_#{area}_cover").present? &&
      presenter.pame_statistic.send("pame_pa_#{area}_area").present?
  end

  def is_malaysia_pa?
    [9786, 555635837, 3150].include?(@protected_area.wdpa_id)
  end

  def management_plan_documents
    [
      {
        url: 'url1',
        name: 'name1'
      },
      {
        url: 'url2',
        name: 'name2'
      }
    ]
  end
end
