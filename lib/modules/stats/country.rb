
class Stats::Country

  IUCN_CATEGORIES = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"

  def self.total_pas iso
    ProtectedArea.select(:id).joins(:countries).where("iso = '#{iso}'").count
  end

  def self.percentage_cover_pas iso
    CountryStatistic.joins(:country)
                     .where("countries.iso" => iso)
                     .first[:percentage_cover_pas]
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

  private


  def self.protected_areas_in_country iso
    ProtectedArea.joins(:countries).where("countries.iso = '#{iso}'")
  end

end