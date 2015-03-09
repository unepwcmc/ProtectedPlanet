require 'test_helper'

class WdpaProtectedAreaImporterIrreplaceabilityTest < ActiveSupport::TestCase
  test '.import should open a CSV file and set the irreplaceability value for the found PAs' do
    pa1 = FactoryGirl.create(:protected_area, wdpa_id: '123')
    pa2 = FactoryGirl.create(:protected_area, wdpa_id: '456')
    pa3 = FactoryGirl.create(:protected_area, wdpa_id: '789')

    parsed_csv = [['123', 'INCLUDED'], ['456', 'INCLUDED']]
    CSV.stubs(:read).returns(parsed_csv)

    Wdpa::ProtectedAreaImporter::IrreplaceabilityImporter.import
    assert pa1.reload.has_irreplaceability_info
    assert pa2.reload.has_irreplaceability_info
    refute pa3.reload.has_irreplaceability_info
  end
end
