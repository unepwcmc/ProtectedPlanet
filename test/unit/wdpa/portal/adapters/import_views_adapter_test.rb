require 'test_helper'

class Wdpa::Portal::Adapters::ImportViewsAdapterTest < ActiveSupport::TestCase
  def setup
    @adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
  end

  test 'protected_areas_relation returns ProtectedAreas adapter' do
    result = @adapter.protected_areas_relation

    assert_instance_of Wdpa::Portal::Adapters::ProtectedAreas, result
  end

  test 'sources_relation returns Sources adapter' do
    result = @adapter.sources_relation

    assert_instance_of Wdpa::Portal::Adapters::Sources, result
  end

  test 'protected_areas_relation creates new instance each time' do
    result1 = @adapter.protected_areas_relation
    result2 = @adapter.protected_areas_relation

    assert_instance_of Wdpa::Portal::Adapters::ProtectedAreas, result1
    assert_instance_of Wdpa::Portal::Adapters::ProtectedAreas, result2
    refute_same result1, result2
  end

  test 'sources_relation creates new instance each time' do
    result1 = @adapter.sources_relation
    result2 = @adapter.sources_relation

    assert_instance_of Wdpa::Portal::Adapters::Sources, result1
    assert_instance_of Wdpa::Portal::Adapters::Sources, result2
    refute_same result1, result2
  end
end
