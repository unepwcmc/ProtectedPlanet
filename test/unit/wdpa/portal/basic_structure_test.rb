require 'test_helper'

class Wdpa::Portal::BasicStructureTest < ActiveSupport::TestCase
  test 'portal modules can be loaded' do
    # Test that we can instantiate the main classes
    assert_nothing_raised do
      Wdpa::Portal::Adapters::ImportTablesAdapter.new
      Wdpa::Portal::Importers::PortalProtectedAreasRelation.new
      Wdpa::Portal::Importers::PortalSourcesRelation.new
    end
  end

  test 'portal adapter returns portal relations' do
    adapter = Wdpa::Portal::Adapters::ImportTablesAdapter.new
    
    assert adapter.portal?
    assert_kind_of Wdpa::Portal::Importers::PortalProtectedAreasRelation, adapter.protected_areas_relation
    assert_kind_of Wdpa::Portal::Importers::PortalSourcesRelation, adapter.sources_relation
  end

  test 'column mapper can be instantiated' do
    assert_nothing_raised do
      Wdpa::Portal::Utils::ColumnMapper
    end
  end

  test 'staging table manager can be instantiated' do
    assert_nothing_raised do
      Wdpa::Portal::Utils::StagingTableManager
    end
  end
end

