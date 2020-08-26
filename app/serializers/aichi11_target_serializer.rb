class Aichi11TargetSerializer
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

  def initialize
    @model = Aichi11Target
  end

  def serialize
    # Get global stats saved in this db table and format accordingly
    global_stats = @model::ATTRIBUTES.keys.map do |attr_name|
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

  # This is only used for global stats
  # It's a shared method between this model and the API module
  # The value is fetched from the db if used here,
  # otherwise it is fetched from the API
  def format_data(endpoint)
    json = {
      id: endpoint,
      title: @model::ATTRIBUTES[endpoint.to_sym],
      charts: []
    }
    chart_json = DEFAULT_CHART_JSON.dup

    # Connectivity is terrestrial only
    if endpoint.to_s == 'well_connected'
      chart_json.merge!({ colour: 'terrestrial', title: 'Terrestrial' })
    end

    value = yield
    target = endpoint.to_s == 'importance' ? nil : instance.public_send("#{endpoint.to_s}_global")
    chart_hash = { value: value, target: target }
    json[:charts] << chart_json.merge!(chart_hash)
    json
  end

  private

  def stats
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

  def instance
    @instance ||= @model.instance
  end
end
