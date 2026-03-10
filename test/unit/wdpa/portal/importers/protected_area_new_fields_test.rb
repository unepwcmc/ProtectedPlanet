require 'test_helper'

class Wdpa::Portal::Importers::ProtectedAreaNewFieldsTest < ActiveSupport::TestCase
  def setup
    # Create staging tables for testing
    Wdpa::Portal::Managers::StagingTableManager.create_staging_tables
  end

  def teardown
    # Clean up staging tables
    Wdpa::Portal::Managers::StagingTableManager.drop_staging_tables
  end
end
