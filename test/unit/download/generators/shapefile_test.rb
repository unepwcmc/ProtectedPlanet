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
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE type = 'Polygon'
    """.squish
    shp_point_query = """
      SELECT *
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE type = 'Point'
    """.squish

    view_name_poly = 'temporary_view_123'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_polygon_query).returns(view_name_poly)
    view_name_point = 'temporary_view_456'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_point_query).returns(view_name_point)

    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, "SELECT * FROM #{view_name_poly}").returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, "SELECT * FROM #{view_name_point}").returns(true)

    appendix_path = "#{Rails.root}/lib/data/documents/Appendix\\ 5\\ _WDPA_Metadata.pdf"
    manual_path = "#{Rails.root}/lib/data/documents/WDPA_Manual_1.0.pdf"
    summary_path = "#{Rails.root}/lib/data/documents/Summary_table_WDPA_attributes.pdf"
    attachments_path = "#{appendix_path} #{summary_path} #{manual_path}"

    Download::Generators::Shapefile.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{shp_polygon_joined_files} #{shp_point_joined_files} #{attachments_path}")

    Download::Generators::Shapefile.generate zip_file_path
  end

  test '#generate returns false if the export fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Generators::Shapefile.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate returns false if the zip fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).twice.returns(true)
    Download::Generators::Shapefile.any_instance.expects(:system).returns(false)

    assert_equal false, Download::Generators::Shapefile.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate removes non-zip files when finished' do
    shp_polygons_paths = [
      './all-polygons.shp',
      './all-polygons.shx',
      './all-polygons.dbf',
      './all-polygons.prj',
      './all-polygons.cpg'
    ]

    shp_points_paths = [
      './all-points.shp',
      './all-points.shx',
      './all-points.dbf',
      './all-points.prj',
      './all-points.cpg'
    ]

    ActiveRecord::Base.connection.stubs(:execute)
    Ogr::Postgres.expects(:export).twice.returns(true)
    Download::Generators::Shapefile.
      any_instance.
      expects(:system)

    FileUtils.expects(:rm_rf).with(shp_polygons_paths)
    FileUtils.expects(:rm_rf).with(shp_points_paths)

    Download::Generators::Shapefile.generate('./all.zip')
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
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE type = 'Polygon'
      AND wdpaid IN (1,2,3)
    """.squish
    shp_point_query = """
      SELECT *
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE type = 'Point'
      AND wdpaid IN (1,2,3)
    """.squish

    view_name_poly = 'temporary_view_123'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_polygon_query).returns(view_name_poly)
    view_name_point = 'temporary_view_456'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_point_query).returns(view_name_point)

    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, "SELECT * FROM #{view_name_poly}").returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, "SELECT * FROM #{view_name_point}").returns(true)

    appendix_path = "#{Rails.root}/lib/data/documents/Appendix\\ 5\\ _WDPA_Metadata.pdf"
    manual_path = "#{Rails.root}/lib/data/documents/WDPA_Manual_1.0.pdf"
    summary_path = "#{Rails.root}/lib/data/documents/Summary_table_WDPA_attributes.pdf"
    attachments_path = "#{appendix_path} #{summary_path} #{manual_path}"

    Download::Generators::Shapefile.
      any_instance.
      expects(:system).
      with("zip -j #{zip_file_path} #{shp_polygon_joined_files} #{shp_point_joined_files} #{attachments_path}")

    Download::Generators::Shapefile.generate zip_file_path, wdpa_ids
  end

  test '#generate, given a path and an empty array of wdpa_ids,
   returns immediately' do
    Download::Generators::Base.any_instance.expects(:system).never
    Ogr::Postgres.expects(:export).never

    refute Download::Generators::Shapefile.generate('./none.zip', [])
  end
end
