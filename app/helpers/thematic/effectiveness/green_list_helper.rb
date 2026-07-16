module Thematic::Effectiveness::GreenListHelper
  def green_list_banner_locals(page = @cms_page)
    locals = {
      page_type_class_name: 'green-list',
      button_text: t('thematic_area.green_list.hero.button_text'),
      button_url: @green_list_view_all_url,
      classes: 'green-list',
      contained: true,
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
