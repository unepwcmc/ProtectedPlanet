require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  test '.generate, called with no arguments, generates download files for all countries' do
    start_time = Time.parse("2013-05-30 14:23")
    Timecop.freeze start_time

    types = [:csv, :shapefile, :kml]
    csv_file_path = File.join(Rails.root, 'tmp', 'all_csv_2013-05-30-1423.csv')
    kml_file_path = File.join(Rails.root, 'tmp', 'all_kml_2013-05-30-1423.kml')
    shp_polygons_file_path = File.join(Rails.root, 'tmp', 'all_shapefile_polygons_2013-05-30-1423.shp')
    shp_points_file_path = File.join(Rails.root, 'tmp', 'all_shapefile_points_2013-05-30-1423.shp')

    query = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"
    shp_polygons_query = """
      SELECT *
      FROM #{Wdpa::Release::IMPORT_VIEW_NAME}
      WHERE ST_GeometryType(the_geom) ILIKE '%poly%'
    """.squish
    shp_points_query = """
      SELECT *
      FROM #{Wdpa::Release::IMPORT_VIEW_NAME}
      WHERE ST_GeometryType(the_geom) ILIKE '%point%'
    """.squish

    Ogr::Postgres.expects(:export).with(types[0], csv_file_path, query)
    Ogr::Postgres.expects(:export).with(types[2], kml_file_path, query)
    Ogr::Postgres.expects(:export).with(types[1], shp_polygons_file_path, shp_polygons_query)
    Ogr::Postgres.expects(:export).with(types[1], shp_points_file_path, shp_points_query)

    download_success = Download.generate
    assert download_success, "Expected Download.generate to return true on success"
  end
end
