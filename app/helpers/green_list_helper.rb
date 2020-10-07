module GreenListHelper
  def chart_row_pa_legend
    [
      {
        theme: 'theme--aqua',
        title: I18n.t('thematic_area.green_list.chart_row_pa.legend_text_1')
      },
      {
        theme: 'theme--blue',
        title: I18n.t('thematic_area.green_list.chart_row_pa.legend_text_2')
      }
    ]
  end
end