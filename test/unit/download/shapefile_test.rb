require 'test_helper'

class DownloadShapefileTest < ActiveSupport::TestCase
  test '#generate, given a zip file path, exports shapefiles for each
   geometry table, and returns them as a single zip' do
    zip_file_path = './all-shp.zip'
    shp_polygon_file_path = './all-shp-polygons.shp'
    shp_polygon_joined_files = './all-shp-polygons.shp ./all-shp-polygons.shx ./all-shp-polygons.dbf ./all-shp-polygons.prj ./all-shp-polygons.cpg'

    shp_point_file_path = './all-shp-points.shp'
    shp_point_joined_files = './all-shp-points.shp ./all-shp-points.shx ./all-shp-points.dbf ./all-shp-points.prj ./all-shp-points.cpg'

    shp_polygon_query = """
      SELECT *
      FROM #{Wdpa::Release::IMPORT_VIEW_NAME}
      WHERE ST_GeometryType(wkb_geometry) LIKE '%Poly'
    """.squish
    shp_point_query = """
      SELECT *
      FROM #{Wdpa::Release::IMPORT_VIEW_NAME}
      WHERE ST_GeometryType(wkb_geometry) LIKE '%Point'
    """.squish

    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, shp_polygon_query).returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, shp_point_query).returns(true)
    Download::Shapefile.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{shp_polygon_joined_files} #{shp_point_joined_files}")

    Download::Shapefile.generate zip_file_path
  end

  test '#generate, given a zip file path and WDPA IDs, exports
   shapefiles for each geometry table, and returns them as a single zip' do
    zip_file_path = './all-shp.zip'
    shp_polygon_file_path = './all-shp-polygons.shp'
    shp_polygon_joined_files = './all-shp-polygons.shp ./all-shp-polygons.shx ./all-shp-polygons.dbf ./all-shp-polygons.prj ./all-shp-polygons.cpg'

    shp_point_file_path = './all-shp-points.shp'
    shp_point_joined_files = './all-shp-points.shp ./all-shp-points.shx ./all-shp-points.dbf ./all-shp-points.prj ./all-shp-points.cpg'

    wdpa_ids = [1,2,3]

    shp_polygon_query = """
      SELECT *
      FROM #{Wdpa::Release::IMPORT_VIEW_NAME}
      WHERE ST_GeometryType(wkb_geometry) LIKE '%Poly'
      AND wdpaid IN (1, 2, 3)
    """.squish
    shp_point_query = """
      SELECT *
      FROM #{Wdpa::Release::IMPORT_VIEW_NAME}
      WHERE ST_GeometryType(wkb_geometry) LIKE '%Point'
      AND wdpaid IN (1, 2, 3)
    """.squish

    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, shp_polygon_query).returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, shp_point_query).returns(true)
    Download::Shapefile.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{shp_polygon_joined_files} #{shp_point_joined_files}")

    Download::Shapefile.generate zip_file_path, wdpa_ids
  end
end
