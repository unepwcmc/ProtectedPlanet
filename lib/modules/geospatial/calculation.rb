class Geospatial::Calculation

  def delete_country_stats
    CountryStatistic.destroy_all
  end

  def insert_country_stats
    insert_country_statistics
  end

  private

  DB = ActiveRecord::Base.connection

  def insert_country_statistics
    sql = insert_query
    DB.execute(sql)
  end

  def insert_query
    """INSERT INTO country_statistics (
            country_id, 
            land_area, 
            eez_area, 
            ts_area, 
            pa_area, 
            pa_land_area, 
            pa_marine_area,
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
            FROM
            (SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area, 
            ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
            ST_Area(ST_Transform(land_geom,954009)) land_area,
            ST_Area(ST_Transform(eez_geom,954009)) eez_area,
            ST_Area(ST_Transform(ts_geom,954009)) ts_Area
            from countries) areas""".squish
  end
end