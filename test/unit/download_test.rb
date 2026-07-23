require 'test_helper'

class DownloadTest < ActiveSupport::TestCase
  # Download.generate(format, download_name, opts) generates ONE format per call.
  # The zip is named <download_name>.zip (no per-format suffix) and uploaded under
  # the current/ prefix (or import/ when for_import: true). See lib/modules/download.rb.
  NAME = 'an_download'.freeze

  def zip_path
    File.join(Rails.root, 'tmp', "#{NAME}.zip")
  end

  def teardown
    FileUtils.rm_f(zip_path)
  end

  test '.generate runs the generator for the format and uploads the zip under the current prefix' do
    # generate checks File.exist?(zip_path) after the (mocked) generator runs.
    File.write(zip_path, '')
    Download::Generators::Shapefile.expects(:generate).with(zip_path, nil).returns(true)
    S3.expects(:upload).with(Download::CURRENT_PREFIX + "#{NAME}.zip", zip_path)

    assert Download.generate('shp', NAME, { site_selection: nil }),
      'Expected Download.generate to return true on success'
  end

  test '.generate with the import option uploads with the import prefix' do
    File.write(zip_path, '')
    Download::Generators::Csv.stubs(:generate).returns(true)
    S3.expects(:upload).with(Download::IMPORT_PREFIX + "#{NAME}.zip", zip_path)

    Download.generate('csv', NAME, { site_selection: nil, for_import: true })
  end

  test '.generate passes the site_selection through to the generator' do
    File.write(zip_path, '')
    site_selection = { site_ids: [1, 2, 3] }
    S3.stubs(:upload)
    Download::Generators::Shapefile.expects(:generate).with(zip_path, site_selection).returns(true)

    assert Download.generate('shp', NAME, { site_selection: site_selection }),
      'Expected Download.generate to return true on success'
  end

  test '.generate removes the zip after uploading to S3' do
    File.write(zip_path, '')
    Download::Generators::Shapefile.stubs(:generate).returns(true)
    S3.stubs(:upload)
    FileUtils.expects(:rm_rf).with(zip_path)

    Download.generate('shp', NAME, { site_selection: nil })
  end

  test '.generate does not upload to S3 if the generator returns false' do
    Download::Generators::Shapefile.expects(:generate).returns(false)
    S3.expects(:upload).never

    assert_not Download.generate('shp', NAME, { site_selection: nil }),
      'Expected Download.generate to return false when the generator fails'
  end

  test '.request, given a hash of params, requests the router with domain and params' do
    params = { 'domain' => 'general', 'id' => 'USA' }
    Download::Router.expects(:request).with('general', { 'id' => 'USA' })

    Download.request params
  end

  test '.set_email, given a hash of params, sets email using the router' do
    params = { 'domain' => 'general', 'id' => '123', 'email' => 'test@test.com' }
    Download::Router.expects(:set_email).with('general', { 'id' => '123', 'email' => 'test@test.com' })

    Download.set_email params
  end
end
