module TargetDashboardHelper
  def getTooltipText id
    tooltip = t("thematic_area.target_11_dashboard.tooltips").select { |_tooltip| _tooltip[:id] == id.to_s }.first

    tooltip ? tooltip[:text] : ''
  end

  def get_config_carousel_t11
    {
      cellAlign: 'left',
      prevNextButtons: false,
      wrapAround: true
    }.to_json
  end
end
