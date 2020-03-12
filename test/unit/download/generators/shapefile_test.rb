require 'test_helper'

class DownloadShapefileTest < ActiveSupport::TestCase
  test '#generate, given a zip file path, exports shapefiles for each
   geometry table, and returns them as a single zip' do
    zip_file_path = './all-shp.zip'
    zip_file_path0 = './all-shp0.zip'
    zip_file_path1 = './all-shp1.zip'
    shp_polygon_file_path = './all-shp-polygons.shp'
    shp_polygon_joined_files = './all-shp-polygons.shp ./all-shp-polygons.shx ./all-shp-polygons.dbf ./all-shp-polygons.prj ./all-shp-polygons.cpg'

    shp_point_file_path = './all-shp-points.shp'
    shp_point_joined_files = './all-shp-points.shp ./all-shp-points.shx ./all-shp-points.dbf ./all-shp-points.prj ./all-shp-points.cpg'

    shp_polygon_query = """
      SELECT #{Download::Utils.download_columns}
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE \"TYPE\" = 'Polygon'
    """.squish
    shp_point_query = """
      SELECT #{Download::Utils.download_columns(reject: [:gis_area, :gis_m_area])}
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE \"TYPE\" = 'Point'
    """.squish

    view_name_poly = 'temporary_view_123'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_polygon_query).returns(view_name_poly)
    view_name_point = 'temporary_view_456'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_point_query).returns(view_name_point)

    ActiveRecord::Base.connection.stubs(:select_value).returns(2)
    poly_query = "SELECT * FROM #{view_name_poly}" << ' ORDER BY \""GIS_AREA"\" DESC'
    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, "#{poly_query} LIMIT 1 OFFSET 0").returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, "#{poly_query} LIMIT 1 OFFSET 1").returns(true)
    point_query = "SELECT * FROM #{view_name_point}"
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, "#{point_query} LIMIT 1 OFFSET 0").returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, "#{point_query} LIMIT 1 OFFSET 1").returns(true)

    create_zip_command = "zip -j #{zip_file_path0} #{shp_polygon_joined_files} #{shp_point_joined_files}"
    Download::Generators::Shapefile.any_instance.expects(:system).with(create_zip_command).returns(true)
    create_zip_command = "zip -j #{zip_file_path1} #{shp_polygon_joined_files} #{shp_point_joined_files}"
    Download::Generators::Shapefile.any_instance.expects(:system).with(create_zip_command).returns(true)

    merge_zip_command = "zip -j #{zip_file_path} #{zip_file_path0} #{zip_file_path1}"
    Download::Generators::Shapefile.any_instance.expects(:system).with(merge_zip_command).returns(true)
    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = {chdir: Download::Generators::Base::ATTACHMENTS_PATH}
    Download::Generators::Shapefile.any_instance.expects(:system).with(update_zip_command, opts).returns(true)


    Download::Generators::Shapefile.generate zip_file_path
  end

  test '#generate returns false if the export fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    ActiveRecord::Base.connection.stubs(:select_value).returns(1)
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Generators::Shapefile.generate(''),
      "Expected #generate to return false on failure"
  end

  test '#generate returns false if the zip fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    ActiveRecord::Base.connection.stubs(:select_value).returns(2)
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

    zip_file_path  = './all.zip'
    zip_file_path0 = './all0.zip'
    zip_file_path1 = './all1.zip'

    ActiveRecord::Base.connection.stubs(:execute)
    ActiveRecord::Base.connection.stubs(:select_value).returns(1).times(4)
    Ogr::Postgres.expects(:export).times(4).returns(true)
    Download::Generators::Shapefile.
      any_instance.
      expects(:system).
      returns(true).
      times(4)

    FileUtils.expects(:rm_rf).with(shp_polygons_paths).twice
    FileUtils.expects(:rm_rf).with(shp_points_paths).twice
    FileUtils.expects(:rm_rf).with(zip_file_path0)
    FileUtils.expects(:rm_rf).with(zip_file_path1)

    Download::Generators::Shapefile.generate(zip_file_path)
  end

  test '#generate, given a zip file path and WDPA IDs, exports
   shapefiles for each geometry table, and returns them as a single zip' do
    zip_file_path  = './all-shp.zip'
    zip_file_path0 = './all-shp0.zip'
    zip_file_path1 = './all-shp1.zip'
    shp_polygon_file_path = './all-shp-polygons.shp'
    shp_polygon_joined_files = './all-shp-polygons.shp ./all-shp-polygons.shx ./all-shp-polygons.dbf ./all-shp-polygons.prj ./all-shp-polygons.cpg'

    shp_point_file_path = './all-shp-points.shp'
    shp_point_joined_files = './all-shp-points.shp ./all-shp-points.shx ./all-shp-points.dbf ./all-shp-points.prj ./all-shp-points.cpg'

    wdpa_ids = [1,2,3]

    shp_polygon_query = """
      SELECT #{Download::Utils.download_columns}
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE \"TYPE\" = 'Polygon'
      AND \"WDPAID\" IN (1,2,3)
    """.squish
    shp_point_query = """
      SELECT #{Download::Utils.download_columns(reject: [:gis_area, :gis_m_area])}
      FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}
      WHERE \"TYPE\" = 'Point'
      AND \"WDPAID\" IN (1,2,3)
    """.squish

    view_name_poly = 'temporary_view_123'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_polygon_query).returns(view_name_poly)
    view_name_point = 'temporary_view_456'
    Download::Generators::Shapefile.any_instance.stubs(:create_view).with(shp_point_query).returns(view_name_point)

    ActiveRecord::Base.connection.stubs(:select_value).returns(1).times(4)
    poly_query = "SELECT * FROM #{view_name_poly}" << ' ORDER BY \""GIS_AREA"\" DESC'
    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, "#{poly_query} LIMIT 1 OFFSET 0").returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path, "#{poly_query} LIMIT 1 OFFSET 1").returns(true)
    point_query = "SELECT * FROM #{view_name_point}"
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, "#{point_query} LIMIT 1 OFFSET 0").returns(true)
    Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path, "#{point_query} LIMIT 1 OFFSET 1").returns(true)

    create_zip_command = "zip -j #{zip_file_path0} #{shp_polygon_joined_files} #{shp_point_joined_files}"
    Download::Generators::Shapefile.any_instance.expects(:system).with(create_zip_command).returns(true)
    create_zip_command = "zip -j #{zip_file_path1} #{shp_polygon_joined_files} #{shp_point_joined_files}"
    Download::Generators::Shapefile.any_instance.expects(:system).with(create_zip_command).returns(true)

    merge_zip_command = "zip -j #{zip_file_path} #{zip_file_path0} #{zip_file_path1}"
    Download::Generators::Shapefile.any_instance.expects(:system).with(merge_zip_command).returns(true)
    update_zip_command = "zip -ru #{zip_file_path} *"
    opts = {chdir: Download::Generators::Base::ATTACHMENTS_PATH}
    Download::Generators::Shapefile.any_instance.expects(:system).with(update_zip_command, opts).returns(true)

    Download::Generators::Shapefile.generate zip_file_path, wdpa_ids
  end

  test '#generate, given a path and an empty array of wdpa_ids,
   returns immediately' do
    Download::Generators::Base.any_instance.expects(:system).never
    Ogr::Postgres.expects(:export).never

    refute Download::Generators::Shapefile.generate('./none.zip', [])
  end

  test '#generate doesnt call Ogr::Postgres::export if the view has no pas' do
    Download::Generators::Shapefile.any_instance.stubs(:create_view).twice
    ActiveRecord::Base.connection.stubs(:select_value).returns(0).twice

    Download::Generators::Base.any_instance.expects(:system)
    Ogr::Postgres.expects(:export).never

    Download::Generators::Shapefile.generate('./none.zip', [1,2,3])
  end
end
