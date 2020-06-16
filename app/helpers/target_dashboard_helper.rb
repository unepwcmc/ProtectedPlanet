module TargetDashboardHelper
  def getTooltipText id
    tooltip = t("thematic_area.target_11_dashboard.tooltips").select { |_tooltip| _tooltip[:id] == id.to_s }.first

    tooltip ? tooltip[:text] : ''
  end

  def get_config_carousel_global
    {
      cellAlign: 'left',
      prevNextButtons: false,
      wrapAround: true
      # navButtons: false,
      # infinite: true,
      # responsive: [
      # {
      #     breakpoint: 628,
      #     settings: {
      #       dots: true,
      #       slidesToShow: 1,
      #     }
      #   },
      #   {
      #     breakpoint: 768,
      #     settings: {
      #       dots: true,
      #       slidesToShow: 2,
      #     }
      #   },
      #   {
      #     breakpoint: 1024,
      #     settings: {
      #       dots: false,
      #       slidesToShow: 5
      #     }
      #   }
      # ]
    }.to_json
  end
end
