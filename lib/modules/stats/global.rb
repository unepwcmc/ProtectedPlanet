class Stats::Global
  IUCN_CATEGORIES = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"

  def self.pa_count 
    ProtectedArea.count
  end

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
end
