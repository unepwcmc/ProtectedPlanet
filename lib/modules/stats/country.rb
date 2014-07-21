class Stats::Country
  IUCN_CATEGORIES = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"

  def self.total_pas iso
    ProtectedArea.select(:id).joins(:countries).where("iso = ?", iso).count
  end

  def self.percentage_global_pas_area iso
    global_stats = RegionalStatistic.joins(:region).where("name = ?", 'Global')
    global_pa_area = global_stats.first[:pa_land_area] + 
                  global_stats.first[:pa_marine_area]
    pa_area = CountryStatistic.joins(:country).where("countries.iso" => iso)
      .first[:pa_area]
    pa_area / global_pa_area * 100
  end

  def self.percentage_global_pas iso
    country_pas = total_pas iso
    global_pas = ProtectedArea.count
    country_pas.to_f / global_pas * 100
  end

  def self.percentage_pa_cover iso
    CountryStatistic.joins(:country)
                     .where("countries.iso" => iso)
                     .first[:percentage_pa_cover]
  end

  def self.pas_with_iucn_category iso
    ProtectedArea.select(:id)
                 .joins(:iucn_category, :countries)
                 .where("iucn_categories.name IN (#{IUCN_CATEGORIES}) AND iso = '#{iso}'")
                 .count
  end

  def self.designation_count iso
    country_protected_areas = protected_areas_in_country(iso)
    country_protected_areas.select('designations.id').joins(:designation).group('designations.id').length
  end

  def self.protected_areas_by_designation iso
    protected_areas = protected_areas_in_country(iso)
    designation_count = protected_areas.select('designations.name, count(*)').joins(:designation).group('designations.name')
    result = {}
    designation_count.each do |designation|
      result.merge!(designation[:name] => designation[:count])
    end
    result
  end

  def self.percentage_protected_land iso
    CountryStatistic.joins(:country).
      where("countries.iso = ?", iso).select(:percentage_pa_land_cover).
      first.percentage_pa_land_cover
  end

  def self.percentage_protected_sea iso
    CountryStatistic.joins(:country).
      where("countries.iso = ?", iso).select(:percentage_pa_eez_cover).
      first.percentage_pa_eez_cover
  end

  def self.percentage_protected_coast iso
    CountryStatistic.joins(:country).
      where("countries.iso = ?", iso).select(:percentage_pa_ts_cover).
      first.percentage_pa_ts_cover
  end

  private

  def self.protected_areas_in_country iso
    ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'")
  end
end
