require 'test_helper'
require 'sidekiq/testing'

class TestWdpaAssetImporterService < ActiveSupport::TestCase
  test '.import, given a WDPA release, enqueues a WikipediaSummaryWorker and
   ImageWorker job for new PAs' do
    pa = FactoryGirl.create(:protected_area)

    Sidekiq::Testing.fake!
    ImportTools.stubs(:current_import).returns(stub_everything)

    Wdpa::ProtectedAreaImporter::AssetImporter.import

    assert_equal 1, ImportWorkers::WikipediaSummaryWorker.jobs.size
    assert_equal 1, ImportWorkers::ImageWorker.jobs.size

    assert_equal(
      pa.id,
      ImportWorkers::WikipediaSummaryWorker.jobs.first['args'].first
    )
    assert_equal(
      pa.id,
      ImportWorkers::ImageWorker.jobs.first['args'].first
    )

    Sidekiq::Worker.clear_all
  end

end
