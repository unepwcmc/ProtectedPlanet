class Stats::Global
  IUCN_CATEGORIES = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"

  def self.percentage_pa_cover
    RegionalStatistic.joins(:region)
                     .where('regions.iso' => 'GLOBAL')
                     .first[:percentage_pa_cover]
  end

  def self.pas_with_iucn_category
    ProtectedArea.joins(:iucn_category)
                 .where("iucn_categories.name IN (#{IUCN_CATEGORIES})")
                 .count
  end

  def self.designation_count
    Designation.count
  end

  def self.protected_areas_by_designation
    protected_areas = ProtectedArea.all
    designation_count = protected_areas.select('designations.name, count(*)').joins(:designation).group('designations.name')
    result = {}
    designation_count.each do |designation|
      result.merge!(designation[:name] => designation[:count])
    end
    result
  end

  def self.countries_providing_data
    ProtectedArea.select("countries.id").joins(:countries).group("countries.id").length
  end

  def self.calculate_stats_for(klass, field_name)
    # Statistics with no country id belong to ABNJ and ATA
    # which should be included in the global stat calculation
    stats = klass.all
    stats.map(&field_name.to_sym).inject(0) do |_sum, x|
      _sum + (x || 0)
    end
  end

  # TODO Double check calculations
  def self.global_area
    CountryStatistic.global_land_area + CountryStatistic.global_marine_area
  end

  def self.percentage_land_cover
    CountryStatistic.global_percentage_pa_land_cover
  end

  def self.percentage_marine_cover
    CountryStatistic.global_percentage_pa_marine_cover
  end
  
end
