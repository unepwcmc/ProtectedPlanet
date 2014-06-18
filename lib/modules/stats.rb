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

  def self.country_total_pas iso
    total_pas_in iso, 'countries'
  end

  def self.country_percentage_cover_pas iso
    CountryStatistic.joins(:country)
                     .where("countries.iso" => iso)
                     .first[:percentage_cover_pas]
  end

  def self.country_pas_with_iucn_category iso
    ProtectedArea.joins(:iucn_category, :countries)
                 .where("iucn_categories.name IN ('Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI') AND iso = '#{iso}'")
                 .count
  end

  def self.country_designation_count iso
    country_protected_areas = ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'")
    country_protected_areas.select('designations.id').joins(:designation).group('designations.id').length
  end

  def self.country_protected_areas_by_designation iso
    country_protected_areas = ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'")
    designation_count = country_protected_areas.select('designations.name, count(*)').joins(:designation).group('designations.name')
    result = {}
    designation_count.each do |designation|
      result.merge!(designation[:name] => designation[:count])
    end
    result
  end 

  private

  def self.total_pas_in entity_code,type
    ProtectedArea.joins(type.to_sym).where("iso = '#{entity_code}'").count
  end
end

