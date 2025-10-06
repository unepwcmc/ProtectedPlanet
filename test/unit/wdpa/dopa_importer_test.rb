require 'test_helper'

class TestDopaImporter < ActiveSupport::TestCase
  test '#import DOPA sites and skip non-existent SITE IDs' do
    DOPA_LIST = "#{Rails.root}/test/unit/wdpa/csv_mocks/dopa_test.csv"

    site_ids = [1, 2, 4, 6]
    site_ids.each do |site_id|
      FactoryGirl.create(:protected_area, site_id: site_id, reported_area: 0.6e2)
    end

    Wdpa::DopaImporter.import

    assert_equal 4, ProtectedArea.where(is_dopa: true).count
  end
end
