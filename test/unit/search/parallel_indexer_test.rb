require 'test_helper'

class SearchParallelIndexerTest < ActiveSupport::TestCase
  test '#index, given an ActiveRecord::Association, creates threads
   to parallelly populate the ES index' do
    2.times { FactoryGirl.create(:protected_area) }

    concurrency_level = 2
    System::CPU.stubs(:count).returns(2)
    Rails.application.secrets.elasticsearch['indexing']['concurrency_level'] = concurrency_level

    Thread.expects(:new).times(8)
    Search::Index.expects(:index).times(2)

    Search::ParallelIndexer.index ProtectedArea.without_geometry
  end
end
