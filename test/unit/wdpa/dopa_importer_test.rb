require 'test_helper'

class TestDopaImporter < ActiveSupport::TestCase
  MOCK_DOPA_LIST = Rails.root.join('test/unit/wdpa/csv_mocks/dopa_test.csv').to_s

  # The importer reads a fixed path (Wdpa::DopaImporter::DOPA_LIST). The real CSV
  # was deleted in "chore: remove unused CSVs", so point the constant at the mock
  # for the duration of the test. The previous version assigned a DOPA_LIST
  # constant in this class, which never overrode the importer's and had no effect.
  def setup
    @original_dopa_list = Wdpa::DopaImporter::DOPA_LIST
    swap_dopa_list(MOCK_DOPA_LIST)
  end

  def teardown
    swap_dopa_list(@original_dopa_list)
  end

  test '#import DOPA sites and skip non-existent SITE IDs' do
    site_ids = [1, 2, 4, 6]
    site_ids.each do |site_id|
      FactoryBot.create(:protected_area, site_id: site_id, reported_area: 0.6e2)
    end

    Wdpa::DopaImporter.import

    assert_equal 4, ProtectedArea.where(is_dopa: true).count
  end

  private

  def swap_dopa_list(path)
    Wdpa::DopaImporter.send(:remove_const, :DOPA_LIST)
    Wdpa::DopaImporter.const_set(:DOPA_LIST, path)
  end
end
