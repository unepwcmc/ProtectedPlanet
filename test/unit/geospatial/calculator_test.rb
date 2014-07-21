require 'test_helper'

class TestGeospatialCalculator < ActiveSupport::TestCase
  test '.calculate_statistics(:country) calculates statistics at the
  Country level' do
    query = """
      INSERT INTO country_statistics (
        country_id, land_area, eez_area, ts_area, pa_area,
        pa_land_area, pa_marine_area, percentage_pa_cover,
        percentage_pa_land_cover, percentage_pa_eez_cover,
        percentage_pa_ts_cover, created_at, updated_at
      )

      SELECT id, land_area, eez_area, ts_area,
        COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
        pa_land_area, pa_marine_area,
        (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) /
          (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
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
        END,
        LOCALTIMESTAMP,
        LOCALTIMESTAMP
        FROM (
          SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area,
            ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
            ST_Area(ST_Transform(land_geom,954009)) land_area,
            ST_Area(ST_Transform(eez_geom,954009)) eez_area,
            ST_Area(ST_Transform(ts_geom,954009)) ts_Area
          FROM countries
        ) areas
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(query)

    calculator = Geospatial::Calculator.new :country
    calculator.calculate_statistics
  end

  test '.calculate_statistics(:regional) calculates statistics at the
   Regional level' do
    query = """
      INSERT INTO regional_statistics (
        region_id, land_area, eez_area, ts_area, pa_area,
        pa_land_area, pa_marine_area, percentage_pa_cover,
        percentage_pa_land_cover, percentage_pa_eez_cover,
        percentage_pa_ts_cover, created_at, updated_at
      )

      SELECT id, land_area, eez_area, ts_area,
        COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
        pa_land_area, pa_marine_area,
        (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) /
          (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
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
        END,
        LOCALTIMESTAMP,
        LOCALTIMESTAMP
        FROM (
          SELECT r.id,
            sum(pa_land_area) pa_land_area,
            sum(pa_marine_area) pa_marine_area,
            sum(land_area) land_area,
            sum(eez_area) eez_area,
            sum(ts_area) ts_area
            FROM country_statistics cs
          JOIN countries c ON cs.country_id = c.id,
          JOIN regions r on r.id = c.region_id
          GROUP BY r.id
        ) areas
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(query)

    calculator = Geospatial::Calculator.new :regional
    calculator.calculate_statistics
  end

  test '.calculate_statistics(:global) calculates statistics at the
   Global level' do
    query = """
      INSERT INTO regional_statistics (
        region_id, land_area, eez_area, ts_area, pa_area,
        pa_land_area, pa_marine_area, percentage_pa_cover,
        percentage_pa_land_cover, percentage_pa_eez_cover,
        percentage_pa_ts_cover, created_at, updated_at
      )

      SELECT id, land_area, eez_area, ts_area,
        COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
        pa_land_area, pa_marine_area,
        (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) /
          (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
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
        END,
        LOCALTIMESTAMP,
        LOCALTIMESTAMP
        FROM (
          SELECT r.id,
            sum(pa_land_area) pa_land_area,
            sum(pa_marine_area) pa_marine_area,
            sum(land_area) land_area,
            sum(eez_area) eez_area,
            sum(ts_area) ts_area
            FROM country_statistics cs
          JOIN countries c ON cs.country_id = c.id,
          regions r
          WHERE r.iso = 'GL'
          GROUP BY r.id
        ) areas
    """.squish

    ActiveRecord::Base.connection.expects(:execute).with(query)

    calculator = Geospatial::Calculator.new :global
    calculator.calculate_statistics
  end

  test '#calculate_statistics creates Calculator instances for global,
   regional and country level statistics and calls .calculate_statistics' do
    calculator = Geospatial::Calculator.new :country

    Geospatial::Calculator.expects(:new).with(:country).returns(calculator)
    Geospatial::Calculator.expects(:new).with(:regional).returns(calculator)
    Geospatial::Calculator.expects(:new).with(:global).returns(calculator)

    calculator.expects(:calculate_statistics).times(3)

    Geospatial::Calculator.calculate_statistics
  end
end
