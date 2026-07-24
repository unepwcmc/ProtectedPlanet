require 'test_helper'

class DownloadShapefileTest < ActiveSupport::TestCase
  SOURCES_FILE = 'WDPA_sources_Jan2024.csv'.freeze

  # Portal-release path is the standard one now (portal downloads view + SITE_ID
  # column). Pin it and the release label so the SQL/filenames are deterministic
  # instead of depending on DB state. export_sources is a separate concern here.
  #
  # The generator now builds its column lists per call in .query_conditions, so
  # the stubs below do reach the SELECT list.
  setup do
    Download::Config.stubs(:has_successful_portal_release?).returns(true)
    Download::Config.stubs(:current_label).returns('Jan2024')
    Download::Generators::Shapefile.any_instance.stubs(:export_sources).returns(true)
  end

  def poly_select
    Download::Generators::Shapefile.query_conditions[:polygons][:select]
  end

  def point_select
    Download::Generators::Shapefile.query_conditions[:points][:select]
  end

  def site_id_col
    Download::Config.download_view_column_names[:site_id]
  end

  # merge_files: merge the piece zips, then add sources, attachments and the
  # shapefile README (each a separate `system` call, chained with `and`).
  def expect_merge_steps(gen, zip_file_path, piece_paths)
    gen.expects(:system).with("zip -j #{zip_file_path} #{piece_paths.join(' ')}").returns(true)
    gen.expects(:system).with("zip -ru #{zip_file_path} #{SOURCES_FILE}", { chdir: '.' }).returns(true)
    gen.expects(:system).with("zip -ru #{zip_file_path} *",
      { chdir: Download::Generators::Base::ATTACHMENTS_PATH }).returns(true)
    gen.expects(:system).with(
      "zip -j #{zip_file_path} #{Download::Generators::Base::SHAPEFILE_README_PATH}"
    ).returns(true)
  end

  test '#generate, given a zip file path, exports shapefiles for each
   geometry table, and returns them as a single zip' do
    zip_file_path = './all-shp.zip'
    shp_polygon_file_path = './all-shp-polygons.shp'
    shp_polygon_joined_files = './all-shp-polygons.shp ./all-shp-polygons.shx ./all-shp-polygons.dbf ./all-shp-polygons.prj ./all-shp-polygons.cpg'
    shp_point_file_path = './all-shp-points.shp'
    shp_point_joined_files = './all-shp-points.shp ./all-shp-points.shx ./all-shp-points.dbf ./all-shp-points.prj ./all-shp-points.cpg'

    shp_polygon_query = "
      SELECT #{poly_select}
      FROM #{Download::Config.downloads_view}
      WHERE \"TYPE\" = 'Polygon'
    ".squish
    shp_point_query = "
      SELECT #{point_select}
      FROM #{Download::Config.downloads_view}
      WHERE \"TYPE\" = 'Point'
    ".squish

    gen = Download::Generators::Shapefile.any_instance
    view_name_poly = 'temporary_view_123'
    gen.stubs(:create_view).with(shp_polygon_query).returns(view_name_poly)
    view_name_point = 'temporary_view_456'
    gen.stubs(:create_view).with(shp_point_query).returns(view_name_point)

    ActiveRecord::Base.connection.stubs(:select_value).returns(3)
    # ORDER BY is applied to the polygons component only.
    poly_query = %(SELECT * FROM #{view_name_poly} ORDER BY "#{site_id_col}" ASC)
    point_query = "SELECT * FROM #{view_name_point}"

    piece_paths = []
    3.times do |i|
      Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path,
        "#{poly_query} LIMIT 1 OFFSET #{i}").returns(true)
      Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path,
        "#{point_query} LIMIT 1 OFFSET #{i}").returns(true)

      piece_path = "./all-shp_#{i}.zip"
      piece_paths << piece_path
      gen.expects(:system)
         .with("zip -j #{piece_path} #{shp_polygon_joined_files} #{shp_point_joined_files}")
         .returns(true)
    end

    expect_merge_steps(gen, zip_file_path, piece_paths)

    Download::Generators::Shapefile.generate zip_file_path
  end

  test '#generate returns false if the export fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    ActiveRecord::Base.connection.stubs(:select_value).returns(1)
    Ogr::Postgres.expects(:export).returns(false)

    assert_equal false, Download::Generators::Shapefile.generate(''),
      'Expected #generate to return false on failure'
  end

  test '#generate returns false if the zip fails' do
    ActiveRecord::Base.connection.stubs(:execute)
    ActiveRecord::Base.connection.stubs(:select_value).returns(2)
    Ogr::Postgres.stubs(:export).returns(true)
    Download::Generators::Shapefile.any_instance.stubs(:system).returns(false)

    assert_equal false, Download::Generators::Shapefile.generate(''),
      'Expected #generate to return false on failure'
  end

  test '#generate removes non-zip files when finished' do
    shp_polygons_paths = %w[
      ./all-polygons.shp ./all-polygons.shx ./all-polygons.dbf
      ./all-polygons.prj ./all-polygons.cpg
    ]
    shp_points_paths = %w[
      ./all-points.shp ./all-points.shx ./all-points.dbf
      ./all-points.prj ./all-points.cpg
    ]

    zip_file_path = './all.zip'

    ActiveRecord::Base.connection.stubs(:execute)
    ActiveRecord::Base.connection.stubs(:select_value).returns(3)
    Ogr::Postgres.stubs(:export).returns(true)
    Download::Generators::Shapefile.any_instance.stubs(:system).returns(true)

    FileUtils.expects(:rm_rf).with(shp_polygons_paths).times(3)
    FileUtils.expects(:rm_rf).with(shp_points_paths).times(3)
    3.times { |i| FileUtils.expects(:rm_rf).with("./all_#{i}.zip") }

    Download::Generators::Shapefile.generate(zip_file_path)
  end

  test '#generate, given a zip file path and SITE IDs, exports
   shapefiles for each geometry table, and returns them as a single zip' do
    zip_file_path = './all-shp.zip'
    shp_polygon_file_path = './all-shp-polygons.shp'
    shp_polygon_joined_files = './all-shp-polygons.shp ./all-shp-polygons.shx ./all-shp-polygons.dbf ./all-shp-polygons.prj ./all-shp-polygons.cpg'
    shp_point_file_path = './all-shp-points.shp'
    shp_point_joined_files = './all-shp-points.shp ./all-shp-points.shx ./all-shp-points.dbf ./all-shp-points.prj ./all-shp-points.cpg'

    site_ids = [1, 2, 3]

    # add_conditions wraps the site-id disjuncts in parentheses.
    shp_polygon_query = "
      SELECT #{poly_select}
      FROM #{Download::Config.downloads_view}
      WHERE \"TYPE\" = 'Polygon'
      AND (\"SITE_ID\" IN (1,2,3))
    ".squish
    shp_point_query = "
      SELECT #{point_select}
      FROM #{Download::Config.downloads_view}
      WHERE \"TYPE\" = 'Point'
      AND (\"SITE_ID\" IN (1,2,3))
    ".squish

    gen = Download::Generators::Shapefile.any_instance
    view_name_poly = 'temporary_view_123'
    gen.stubs(:create_view).with(shp_polygon_query).returns(view_name_poly)
    view_name_point = 'temporary_view_456'
    gen.stubs(:create_view).with(shp_point_query).returns(view_name_point)

    ActiveRecord::Base.connection.stubs(:select_value).returns(3)
    poly_query = %(SELECT * FROM #{view_name_poly} ORDER BY "#{site_id_col}" ASC)
    point_query = "SELECT * FROM #{view_name_point}"

    piece_paths = []
    3.times do |i|
      Ogr::Postgres.expects(:export).with(:shapefile, shp_polygon_file_path,
        "#{poly_query} LIMIT 1 OFFSET #{i}").returns(true)
      Ogr::Postgres.expects(:export).with(:shapefile, shp_point_file_path,
        "#{point_query} LIMIT 1 OFFSET #{i}").returns(true)

      piece_path = "./all-shp_#{i}.zip"
      piece_paths << piece_path
      gen.expects(:system)
         .with("zip -j #{piece_path} #{shp_polygon_joined_files} #{shp_point_joined_files}")
         .returns(true)
    end

    expect_merge_steps(gen, zip_file_path, piece_paths)

    Download::Generators::Shapefile.generate zip_file_path, { site_ids: site_ids }
  end

  test '#generate, given a path and an empty selection, returns immediately' do
    Download::Generators::Base.any_instance.expects(:system).never
    Ogr::Postgres.expects(:export).never

    refute Download::Generators::Shapefile.generate('./none.zip', { site_ids: [] })
  end

  test '#generate doesnt call Ogr::Postgres::export if the view has no pas' do
    # 3 selected sites => 3 pieces, each creating a view per component.
    Download::Generators::Shapefile.any_instance.stubs(:create_view)
    ActiveRecord::Base.connection.stubs(:select_value).returns(0)
    Download::Generators::Shapefile.any_instance.stubs(:system).returns(true)

    Ogr::Postgres.expects(:export).never

    Download::Generators::Shapefile.generate('./none.zip', { site_ids: [1, 2, 3] })
  end
end
