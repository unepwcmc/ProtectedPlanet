module Thematic::Effectiveness::GreenListHelper
  def green_list_banner_locals(page = @cms_page)
    locals = {
      button_text: t('thematic_area.green_list.hero.button_text'),
      button_url: @green_list_view_all_url,
      stats_items: green_list_banner_stats_items
    }

    title = cms_fragment_content(:green_list_banner_title, page)
    summary = cms_fragment_content(:green_list_banner_description, page)
    image = cms_fragment_render(:green_list_banner_image, page)

    locals[:title] = title if title.present?
    locals[:summary] = summary if summary.present?
    locals[:image] = image if image.present?

    locals
  end

  def green_list_banner_stats_items
    [
      {
        total: @greenlisted_pas_percent,
        text: t('thematic_area.green_list.hero.stat_text_1'),
        decimal: 2,
        suffix: '%'
      },
      {
        total: @greenlisted_pas_total_count,
        text: t('thematic_area.green_list.hero.stat_text_2'),
        decimal: 0,
        small_number: true
      },
      {
        total: @greenlisted_pas_km,
        text: t('thematic_area.green_list.hero.stat_text_3'),
        decimal: 0,
        small_number: true,
        suffix: 'km<sup>2</sup>'
      }
    ]
  end

  def total_coverage_chart_data
    {
      total: {
        title: I18n.t('thematic_area.green_list.chart_row_pa.legend_text_2'),
        legend_colour_class: 'tw-shared-chart-legend-colour-blue',
        value: @global_oecms_pas_coverage_percentage
      },
      coverage: {
        title: I18n.t('thematic_area.green_list.chart_row_pa.legend_text_1'),
        legend_colour_class: 'tw-shared-chart-legend-colour-aqua',
        value: @greenlisted_pas_percent
      }
    }
  end
end
