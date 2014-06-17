class Stats
  def self.global_pa_count 
    ProtectedArea.count
  end

  def self.global_percentage_cover_pas
    RegionalStatistic.joins(:region)
                     .where('regions.name' => 'global')
                     .first[:percentage_cover_pas]
  end

  def self.global_pas_with_iucn_category
    ProtectedArea.joins(:iucn_category)
                 .where("iucn_categories.name IN ('Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI')")
                 .count
  end

  def self.global_designation_count
    Designation.count
  end

  def self.global_protected_areas_by_designation
    designation_count = Designation.select("designations.name, count(*)").joins(:protected_areas).group("designations.id, designations.name")
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

