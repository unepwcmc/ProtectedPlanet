require 'test_helper'

class SearchParallelIndexerTest < ActiveSupport::TestCase
  test '#index, given an ActiveRecord::Association, creates threads
   to parallelly populate the ES index' do
    10.times { FactoryGirl.create(:protected_area) }

    concurrency_level = 1
    batch_size = 5
    System::CPU.stubs(:count).returns(2)
    Rails.application.secrets.elasticsearch['indexing']['concurrency_level'] = concurrency_level
    Rails.application.secrets.elasticsearch['indexing']['batch_size'] = batch_size

    Search::Index.expects(:index).twice

    Search::ParallelIndexer.index ProtectedArea.without_geometry
  end
end
