module TargetDashboardHelper
  def getTooltipText(id)
    tooltip = t("thematic_area.target_11_dashboard.tooltips").select { |_tooltip| _tooltip[:id] == id.to_s }.first
    tooltip ? t("thematic_area.target_11_dashboard.#{id}_text", geo_type: 'global') : ''
  end

  def region_and_country_tooltips
    t("thematic_area.target_11_dashboard.tooltips").map do |tooltip|
      id = tooltip[:id]
      {
        id: id,
        title: tooltip[:title],
        text: t("thematic_area.target_11_dashboard.#{id}_text", geo_type: 'the country/region\'s')
      }
    end.to_json
  end

  def get_config_carousel_t11
    {
      cellAlign: 'left',
      prevNextButtons: false,
      wrapAround: true
    }.to_json
  end
end
