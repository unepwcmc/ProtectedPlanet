class MarineController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include MapHelper

  def index
    marine_total_pas_count
    marine_statistics
    maine_protected_areas_growth
    marine_stats_items
    num_of_marine_protected_areas
    
    @view_all_marine_pas_url = search_areas_path(filters: SearchAreaLinkFilters.is_type_marine_filters)
    # Removed mpa_map from ['csv', 'shp', 'gdb', 'map_map'] in feat/hide-mpa-download-button
    @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'general', 'marine')


    @map = {
      overlays: MapOverlaysSerializer.new(marine_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'marine',
      point_query_services: marine_services_for_point_query
    }
    @filters = SearchAreaLinkFilters.wdpa_and_marine_is_true_filters
  end

  private


  def marine_data_cache_version
    @marine_data_cache_version ||= (ProtectedArea.maximum(:updated_at)&.to_i || 0)
  end

  def global_stats_cache_version
    @global_stats_cache_version ||= (GlobalStatistic.maximum(:updated_at)&.to_i || 0)
  end

  def num_of_marine_protected_areas
    @num_of_marine_protected_areas ||= ProtectedArea.marine_areas.limit(3)
  end

  def marine_total_pas_count
    @marine_total_pas_count ||= Rails.cache.fetch(
      "marine/marine_total_pas_count/#{marine_data_cache_version}",
      expires_in: 12.days
    ) { number_with_delimiter(ProtectedArea.marine_areas.count()) }
  end

  def marine_statistics
    @marine_statistics ||= Rails.cache.fetch(
      "marine/statistics/#{global_stats_cache_version}",
      expires_in: 12.days
    ) { GlobalStatistic.marine_stats }
  end

  def maine_protected_areas_growth
    @marine_protected_areas_growth ||= Rails.cache.fetch(
      "marine/maine_protected_areas_growth/#{marine_growth_cache_version}",
      expires_in: 12.days
    ) {
        {
          # x = x axis
          # 1, 2, 3 = series on the chart and also make the y axis
          datapoints: marine_growth_datapoints_from_csv,
          units: "km2",
          legend: ["National", "ABNJ", "Global"]
        }.to_json
      }
  end

  def marine_stats_items
    @marine_stats_items ||= Rails.cache.fetch(
      "marine/marine_stats_items/#{I18n.locale}/#{global_stats_cache_version}",
      expires_in: 12.days
    ) do
      [
        {
          total: marine_statistics['total_ocean_pa_coverage_percentage'],
          text: t('thematic_area.marine.hero.stat_text_1'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: marine_statistics['total_marine_protected_areas'],
          text: t('thematic_area.marine.hero.stat_text_2'),
          decimal: 0,
          small_number: true
        },
        {
          # TODO: Once stats server is hooked up, we will have a dedicated field for this
          total: marine_statistics['total_ocean_oecms_pas_coverage_percentage'].to_f - @marine_statistics['total_ocean_pa_coverage_percentage'].to_f,
          text: t('thematic_area.marine.hero.stat_text_3'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: marine_statistics['total_marine_oecms'].to_i,
          text: t('thematic_area.marine.hero.stat_text_4'),
          decimal: 0,
          small_number: true
        },
        {
          total: marine_statistics['total_ocean_oecms_pas_coverage_percentage'],
          text: t('thematic_area.marine.hero.stat_text_5'),
          decimal: 2,
          suffix: '%',
          small_number: true
        },
        {
          total: marine_statistics['total_ocean_area_oecms_pas'],
          text: t('thematic_area.marine.hero.stat_text_6'),
          decimal: 0,
          suffix: 'km<sup>2</sup>',
          small_number: true
        }
      ]
    end
  end

  def marine_overlays
    overlays(['oecm_marine', 'marine_wdpa'], {
      marine_wdpa: {
        isShownByDefault: true
      }
    })
  end

  def marine_growth_csv_path
    ::Utilities::Files.latest_file_by_glob('lib/data/seeds/marine_protected_areas_growth_*.csv')
  end

  def marine_growth_cache_version
    path = marine_growth_csv_path
    path.present? && File.exist?(path) ? File.mtime(path).to_i : 0
  end

  def marine_growth_datapoints_from_csv
    path = marine_growth_csv_path
    return [] unless path.present? && File.exist?(path)

    CSV.foreach(path, headers: true).map do |row|
      {
        x: marine_growth_row_date(row),
        "1": row.fetch('national_waters').to_i,
        "2": row.fetch('abnj').to_i,
        "3": row.fetch('global_ocean').to_i
      }
    end
  rescue => e
    Rails.logger.error("Failed to parse marine growth CSV: #{e.message}")
    []
  end

  def marine_growth_row_date(row)
    date_value = row['year'].to_s.strip
    raise KeyError, "Missing date/year column" if date_value.blank?

    return Time.new(date_value.to_i, 1, 1) if date_value.match?(/\A\d{4}\z/)

    Date.parse(date_value.to_s).to_time
  end
end
