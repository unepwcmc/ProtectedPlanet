module MarineHelper
  def chart_row_pa_legend_national
    [
      {
        theme: 'theme--aqua',
        title: I18n.t('thematic_area.marine.ocean.legend_text_1')
      },
      {
        theme: 'theme--purple',
        title: t('thematic_area.marine.ocean.legend_text_2'),
      }
    ]
  end

  def chart_row_pa_legend_high_seas
    [
      {
        theme: 'theme--aqua',
        title: I18n.t('thematic_area.marine.ocean.legend_text_1')
      },
      {
        theme: 'theme--blue',
        title: t('thematic_area.marine.ocean.legend_text_3'),
      }
    ]
  end
  
  def marine_stats(key)
    statistic = @marine_statistics[key]

    statistic == nil ? 0 : statistic
  end
end