class Aichi11Target < ActiveRecord::Base
  validates_inclusion_of :singleton_guard, :in => [0]

  def self.instance
    first || import
  end

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
    global_stats = Stats::CountryStatisticsApi.get_global_stats
    stats.each do |name, attributes|
      json = { title: attributes[:name], charts: [] }
      terrestrial_chart = DEFAULT_CHART_JSON.merge(**TERRESTRIAL, **attributes[:terrestrial])
      marine_chart = DEFAULT_CHART_JSON.merge(**MARINE, **attributes[:marine])
      json[:charts] = [terrestrial_chart, marine_chart]
      global_stats << json.dup
    end
    global_stats
  end

  private

  def self.import
    CSV.foreach(aichi11_target_csv_path, headers: true) do |row|
      return create({}.merge(row))
    end
  end

  def self.aichi11_target_csv_path
    Rails.root.join('lib/data/seeds/aichi11_targets.csv')
  end

  def self.stats
    {
      coverage: {
        name: 'Coverage',
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
end
