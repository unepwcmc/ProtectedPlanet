class Aichi11Target < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, :in => [0]

  def self.instance
    first || import
  end

  # Refresh representative, well_connected and importance values
  # by fetching data again from the API
  def self.refresh_values
    obj = first
    unless obj
      import
      return
    end
    obj.update_attributes(Stats::CountryStatisticsApi.global_stats_for_import)
  end

  ATTRIBUTES = {
    representative: 'Representative',
    well_connected: 'Well connected',
    importance: 'Areas of importance for biodiversity'
  }.freeze
  TERRESTRIAL = {
    title: 'Terrestrial',
    colour: 'terrestrial'
  }.freeze
  MARINE = {
    title: 'Marine',
    colour: 'marine'
  }.freeze
  # Global by default for both national and global stats
  # as the API stats are not currently split between marine and terrestrial
  DEFAULT_CHART_JSON = {
    title: 'Global',
    colour: 'global',
    value: nil,
    target: nil
  }.freeze
  def self.get_global_stats
    # Get global stats saved in this db table and format accordingly
    global_stats = ATTRIBUTES.keys.map do |attr_name|
      format_data(attr_name) do
        instance.public_send("#{attr_name}_global_value")
      end
    end

    pp_global_stats = []
    stats.each do |name, attributes|
      json = { id: attributes[:slug], title: attributes[:name], charts: [] }
      terrestrial_chart = DEFAULT_CHART_JSON.merge(**TERRESTRIAL, **attributes[:terrestrial])
      marine_chart = DEFAULT_CHART_JSON.merge(**MARINE, **attributes[:marine])
      json[:charts] = [terrestrial_chart, marine_chart]
      pp_global_stats << json.dup
    end
    global_stats.unshift(*pp_global_stats)
  end

  def self.import
    # Import representative, well_connected and importance values from API
    global_values = Stats::CountryStatisticsApi.global_stats_for_import
    # Import targets from file
    CSV.foreach(aichi11_target_csv_path, headers: true) do |row|
      return create({}.merge(row).merge(global_values))
    end
  end

  def self.aichi11_target_csv_path
    Rails.root.join('lib/data/seeds/aichi11_targets.csv')
  end

  def self.stats
    {
      coverage: {
        name: 'Coverage',
        slug: 'coverage',
        terrestrial: {
          value: CountryStatistic.global_percentage_pa_land_cover,
          target: instance.coverage_terrestrial
        },
        marine: {
          value: CountryStatistic.global_percentage_pa_marine_cover,
          target: instance.coverage_marine
        }
      },
      effectively_managed: {
        name: 'Effectively managed',
        slug: 'effectively_managed',
        terrestrial: {
          value: PameStatistic.global_pame_percentage_pa_land_cover,
          target: instance.effectively_managed_terrestrial
        },
        marine: {
          value: PameStatistic.global_pame_percentage_pa_marine_cover,
          target: instance.effectively_managed_marine
        }
      }
    }
  end

  # This is only used for global stats
  # It's a shared method between this model and the API module
  # The value is fetched from the db if used here,
  # otherwise it is fetched from the API
  def self.format_data(endpoint)
    json = {
      id: endpoint,
      title: ATTRIBUTES[endpoint.to_sym],
      charts: []
    }
    chart_json = DEFAULT_CHART_JSON.dup

    value = yield
    target = instance.public_send("#{endpoint.to_s}_global")
    json[:charts] << chart_json.merge!({ value: value, target: target })
    json
  end

  private_class_method :import, :aichi11_target_csv_path, :stats
end
