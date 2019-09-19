module TargetDashboardHelper
  def getTooltipText id
    t("thematic_area.target_11_dashboard.tooltips").select { |tooltip| tooltip[:id] == id }
  end
end
