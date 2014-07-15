require 'test_helper'

class TestGeospatialCalculation < ActiveSupport::TestCase
  test '.deletes current countries_statistics values' do
    CountryStatistic.expects(:destroy_all).returns(:true)

    geometry_calculator = Geospatial::Calculation.new()
    response = geometry_calculator.delete_country_stats

    assert response,"Expects delete_all to be run"
  end

  test '.inserts countries' do
    ActiveRecord::Base.connection.
    expects(:execute).
    with("""INSERT INTO country_statistics (
            country_id, 
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
            FROM
            (SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area, 
            ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
            ST_Area(ST_Transform(land_geom,954009)) land_area,
            ST_Area(ST_Transform(eez_geom,954009)) eez_area,
            ST_Area(ST_Transform(ts_geom,954009)) ts_Area
            from countries) areas""".squish).
    returns true

    geometry_calculator = Geospatial::Calculation.new()
    response = geometry_calculator.insert_country_stats

    assert response, 'Expects query'
    
  end

  test '.inserts countries' do
      ActiveRecord::Base.connection.
    expects(:execute).
    with("""INSERT INTO regional_statistics
            (
            region_id, 
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
            SELECT id, land_area, eez_area, ts_area, 
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
            FROM
              (SELECT r.id, 
                sum(pa_land_area) pa_land_area, 
                sum(pa_marine_area) pa_marine_area, 
                sum(land_area) land_area, 
                sum(eez_area) eez_area, 
                sum(ts_sArea) ts_area
                FROM country_statistics cs
              JOIN countries c ON cs.country_id = c.id
              RIGHT JOIN regions r on r.id = c.region_id
              group by r.iso, r.id) a""".squish).
    returns true

    geometry_calculator = Geospatial::Calculation.new()
    response = geometry_calculator.insert_regional_stats

    assert response, 'Expects query'
    
  end


end