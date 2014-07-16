class Geospatial::Calculation

  def delete_country_stats
    CountryStatistic.destroy_all
  end

  def insert_country_stats
    execute_query 'country'
  end

  def insert_regional_stats
    execute_query 'regional'
  end

  def insert_global_stats
    execute_query 'global'
  end


  private

  DB = ActiveRecord::Base.connection

  def execute_query type
    from_query = send "from_#{type}_query"

    sql = """#{main_query type} #{from_query}""".squish
    DB.execute(sql)
  end


  def main_query type
    id_prefix = type == 'country' ? 'country' : 'region'
    table = type == 'global' ? 'regional' : type
    """ INSERT INTO #{table}_statistics (
        #{id_prefix}_id,
        land_area,
        eez_area,
        ts_area,
        pa_area,
        pa_land_area,
        pa_marine_area,
        percentage_pa_cover,
        percentage_pa_land_cover,
        percentage_pa_eez_cover,
        percentage_pa_ts_cover)
        SELECT
        id,
        land_area,
        eez_area,
        ts_area,
        COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
        pa_land_area,
        pa_marine_area,
        (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) / (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
        COALESCE(pa_land_area,0) / land_area * 100,
        CASE
          WHEN eez_area = 0 THEN
          0
          ELSE
          COALESCE(pa_marine_area,0) / eez_area * 100
        END,
        CASE
          WHEN ts_area = 0 THEN
          0
          ELSE
          COALESCE(pa_marine_area,0) / ts_area * 100
        END
        FROM """
  end

  def from_country_query
    """ (SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area,
        ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
        ST_Area(ST_Transform(land_geom,954009)) land_area,
        ST_Area(ST_Transform(eez_geom,954009)) eez_area,
        ST_Area(ST_Transform(ts_geom,954009)) ts_Area
        from countries) areas"""
  end

    def from_regional_query
      """#{from_regional_table_query} JOIN regions r on r.id = c.region_id
         GROUP BY r.id) a"""
    end

    def from_global_query
      """#{from_regional_table_query}, 
          regions r
          where r.iso = 'GL'
          group by r.id) a"""
    end

    def from_regional_table_query
      """(SELECT r.id,
          sum(pa_land_area) pa_land_area, 
          sum(pa_marine_area) pa_marine_area, 
          sum(land_area) land_area, 
          sum(eez_area) eez_area, 
          sum(ts_area) ts_area
          FROM country_statistics cs
        JOIN countries c ON cs.country_id = c.id
      """
    end
end
