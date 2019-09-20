module TargetDashboardHelper
  def getTooltipText id
    tooltip = t("thematic_area.target_11_dashboard.tooltips").select { |tooltip| tooltip[:id] == id }

    tooltip[0][:text]
  end
end
