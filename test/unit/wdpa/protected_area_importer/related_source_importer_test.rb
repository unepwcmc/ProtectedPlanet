require 'test_helper'

class WdpaProtectedAreaImporterRelatedSourceImporterTest < ActiveSupport::TestCase
  test '::import should open a CSV file and set the given field for the found PAs' do
    expected_path = 'lib/data/some_path.csv'
    pa1 = FactoryGirl.create(:protected_area, site_id: '123')
    pa2 = FactoryGirl.create(:protected_area, site_id: '456')
    pa3 = FactoryGirl.create(:protected_area, site_id: '789')

    parsed_csv = [%w[123 INCLUDED], %w[456 INCLUDED]]
    CSV.stubs(:read).with(expected_path).returns(parsed_csv)

    Wdpa::ProtectedAreaImporter::RelatedSourceImporter.import(
      path: expected_path, field: :has_irreplaceability_info
    )

    assert pa1.reload.has_irreplaceability_info
    assert pa2.reload.has_irreplaceability_info
    refute pa3.reload.has_irreplaceability_info
  end
end
