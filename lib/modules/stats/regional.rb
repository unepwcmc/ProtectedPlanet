class Stats::Regional

  IUCN_CATEGORIES = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
  DB = ActiveRecord::Base.connection

  def self.total_pas iso
    countries_list = countries_in_region iso
    countries_list.joins(:protected_areas).count
  end

  def self.percentage_cover_pas iso
    RegionalStatistic.joins(:region)
                     .where("regions.iso" => iso)
                     .first[:percentage_cover_pas]
  end

  def self.pas_with_iucn_category iso
    sql = """SELECT count(1) FROM regions rg 
              RIGHT JOIN countries ct ON region_id = rg.id
              JOIN countries_protected_areas cpa ON country_id = ct.id
              JOIN protected_areas pa ON protected_area_id = pa.id
              JOIN iucn_categories ic ON iucn_category_id = ic.id
              WHERE rg.iso =? AND ic.name IN (#{IUCN_CATEGORIES})""".squish
    sql_sanitized = ActiveRecord::Base.__send__(:sanitize_sql, [sql, iso], '')
    result = DB.execute(sql_sanitized)
    result[0]["count"].to_i
  end

  def self.designation_count iso
    sql = """SELECT count(1) FROM
                (SELECT ds.id FROM regions rg 
                  RIGHT JOIN countries ct ON region_id = rg.id
                  JOIN countries_protected_areas cpa ON country_id = ct.id
                  JOIN protected_areas pa ON protected_area_id = pa.id
                  JOIN designations ds ON designation_id = ds.id
                  WHERE rg.iso =? 
                  GROUP BY ds.id) a""".squish
    sql_sanitized = ActiveRecord::Base.__send__(:sanitize_sql, [sql, iso], '')
    result = DB.execute(sql_sanitized)
    result[0]["count"].to_i
  end 

  def self.protected_areas_by_designation iso
    sql = """SELECT ds.name, count(1) FROM regions rg 
                  RIGHT JOIN countries ct ON region_id = rg.id
                  JOIN countries_protected_areas cpa ON country_id = ct.id
                  JOIN protected_areas pa ON protected_area_id = pa.id
                  JOIN designations ds ON designation_id = ds.id
                  WHERE rg.iso =? 
                  GROUP BY ds.id""".squish
    sql_sanitized = ActiveRecord::Base.__send__(:sanitize_sql, [sql, iso], '')
    result = DB.execute(sql_sanitized)
    result_hash = {}
    result.each do |designation|
      result_hash.merge!(designation["name"] => designation["count"].to_i)
    end
    result_hash
  end

  def self.countries_providing_data iso
    countries_list = countries_in_region iso
    countries_list.joins(:protected_areas).group("countries.id").length
  end

  private

  def self.countries_in_region iso
    Country.joins(:region).where("regions.iso = '#{iso}'")
  end


end