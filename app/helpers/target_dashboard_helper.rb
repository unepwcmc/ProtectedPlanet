module TargetDashboardHelper
  def getTooltipText id
    tooltip = t("thematic_area.target_11_dashboard.tooltips").select { |_tooltip| _tooltip[:id] == id.to_s }.first

    tooltip ? tooltip[:text] : ''
  end
end
