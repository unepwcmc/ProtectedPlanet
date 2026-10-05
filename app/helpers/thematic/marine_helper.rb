module Thematic::MarineHelper
  def total_coverage_chart_national_data
    {
      total: {
        title: t('thematic_area.marine.ocean.legend_text_2'),
        legend_colour_class: 'tw-shared-chart-legend-colour-purple',
        value: marine_stats('national_waters_percentage')
      },
      coverage: {
        title: I18n.t('thematic_area.marine.ocean.legend_text_1'),
        legend_colour_class: 'tw-shared-chart-legend-colour-aqua',
        value: marine_stats('national_waters_pa_coverage_percentage')
      }
    }
  end

  def total_coverage_chart_high_seas_data
    {
      total: {
        title: t('thematic_area.marine.ocean.legend_text_3'),
        legend_colour_class: 'tw-shared-chart-legend-colour-blue',
        value: marine_stats('global_ocean_percentage')
      },
      coverage: {
        title: I18n.t('thematic_area.marine.ocean.legend_text_1'),
        legend_colour_class: 'tw-shared-chart-legend-colour-aqua',
        value: marine_stats('high_seas_pa_coverage_percentage')
      }
    }
  end

  def marine_stats(key)
    statistic = @marine_statistics[key]

    statistic == nil ? 0 : statistic
  end
end
