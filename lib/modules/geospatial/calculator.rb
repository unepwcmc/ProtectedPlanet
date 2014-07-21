class Geospatial::Calculator
  BASE_QUERY_TEMPLATE = File.expand_path(
    File.join('../templates', 'base_calculation.erb'), __FILE__
  )

  def self.calculate_statistics
    new(:country).calculate_statistics
    new(:regional).calculate_statistics
    new(:global).calculate_statistics
  end

  def initialize level
    @level = level.to_s
  end

  def calculate_statistics
    DB.execute render_template BASE_QUERY_TEMPLATE, binding
  end

  private

  DB = ActiveRecord::Base.connection

  def render_template template_path, binding
    template = ERB.new(File.read(template_path))
    template.result(binding).squish
  end

  def table_name
    prefix = (@level == 'global') ? 'regional' : @level
    "#{prefix}_statistics"
  end

  def id_attribute
    prefix = (@level == 'country') ? 'country' : 'region'
    "#{prefix}_id"
  end

  def from_query
    File.read(
      File.expand_path File.join('../templates', "#{@level}_statistics_query.erb"), __FILE__
    )
  end

  def self.clear_cache
    CountryStatistic.destroy_all
    RegionalStatistic.destroy_all
  end
end
