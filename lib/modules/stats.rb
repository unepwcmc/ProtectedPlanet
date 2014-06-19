class Stats

  IUCN_CATEGORIES = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"

  #Global Statistics


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
                 .where("iucn_categories.name IN (#{IUCN_CATEGORIES})")
                 .count
  end

  def self.global_designation_count
    Designation.count
  end

  def self.global_protected_areas_by_designation
    global_protected_areas = ProtectedArea.all
    protected_areas_by_designation global_protected_areas 
  end

  def self.countries_providing_data
    ProtectedArea.select("countries.id").joins(:countries).group("countries.id").length
  end
  # Regions
  def self.region_total_pas iso
    countries_in_region = Country.joins(:region).where("regions.iso = '#{iso}'")
    countries_in_region.joins(:protected_areas).count
  end

  def self.region_percentage_cover_pas iso
    RegionalStatistic.joins(:region)
                     .where("regions.iso" => iso)
                     .first[:percentage_cover_pas]
  end



  #Countries

  def self.country_total_pas iso
    ProtectedArea.joins(:countries).where("iso = '#{iso}'").count
  end

  def self.country_percentage_cover_pas iso
    CountryStatistic.joins(:country)
                     .where("countries.iso" => iso)
                     .first[:percentage_cover_pas]
  end

  def self.country_pas_with_iucn_category iso
    ProtectedArea.joins(:iucn_category, :countries)
                 .where("iucn_categories.name IN (#{IUCN_CATEGORIES}) AND iso = '#{iso}'")
                 .count
  end

  def self.country_designation_count iso
    country_protected_areas = protected_areas_in_country(iso)
    country_protected_areas.select('designations.id').joins(:designation).group('designations.id').length
  end

  def self.country_protected_areas_by_designation iso
    country_protected_areas = protected_areas_in_country(iso)
    protected_areas_by_designation(country_protected_areas)
  end 

  private

  def self.protected_areas_in_country iso
    ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'")
  end

  def self.protected_areas_by_designation protected_areas
    designation_count = protected_areas.select('designations.name, count(*)').joins(:designation).group('designations.name')
    result = {}
    designation_count.each do |designation|
      result.merge!(designation[:name] => designation[:count])
    end
    result
  end
end

