require 'test_helper'

class TestDopaImporter < ActiveSupport::TestCase
  test "#import DOPA sites and skip non-existent WDPA IDs" do
    DOPA_LIST = "#{Rails.root}/test/unit/wdpa/csv_mocks/dopa_test.csv"

    wdpa_ids = [1, 2, 4, 6]
    wdpa_ids.each do |wdpa_id|
      FactoryGirl.create(:protected_area, wdpa_id: wdpa_id)
    end

    Wdpa::DopaImporter.import

    assert_equal 4, ProtectedArea.where(is_dopa: true).count   
  end

end
