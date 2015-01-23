require 'test_helper'

class ProtectedAreaPresenterTest < ActiveSupport::TestCase
  test '#data_info returns an hash of sections, with the information
   on the protected area\'s attributes' do
    pa = FactoryGirl.create(
      :protected_area,
      wdpa_parent_id: '123',
      sources: [FactoryGirl.create(:source)],
      name: 'San Guillermo',
      original_name: 'San Guillermo',
      marine: true,
      gis_area: 0.0000231,
      countries: [FactoryGirl.create(:country)],
      iucn_category: FactoryGirl.create(:iucn_category),
      designation: FactoryGirl.create(:designation)
    )

    expected_response = {
      'Basic Info' => [
        {label: 'WDPA ID', complete: true},
        {label: 'WDPA Parent ID', complete: true},
        {label: 'Source', complete: true},
        {label: 'Name', complete: true},
        {label: 'Original Name', complete: true},
        {label: 'Marine/Terrestrial', complete: true}
      ], 'Geometries' => [
        {label: 'GIS Marine Area', complete: false},
        {label: 'GIS Area', complete: true},
        {label: 'Geometry', complete: false}
      ], 'Categorisation' => [
        {label: 'Country', complete: true},
        {label: 'Sublocations', complete:false},
        {label: 'IUCN Category', complete: true},
        {label: 'Governance', complete: true},
        {label: 'Management Authority', complete: false},
        {label: 'Management Plan', complete: false},
        {label: 'International Criteria', complete: false},
        {label: 'Designation', complete: true},
        {label: 'Jurisdiction', complete: false}
      ], 'Special' => [
        {label: 'No-take Status', complete: false},
        {label: 'No-take Area', complete: false}
      ]
    }

    presenter = ProtectedAreaPresenter.new(pa)

    assert_equal expected_response, presenter.data_info
  end

  test '#percentage_complete returns the percentage
   of the WDPA attributes that are filled' do
    pa = FactoryGirl.create(:protected_area,
      wdpa_id: 1234,
      name: 'An Protected Area',
      original_name: 'Not an protected area'
    )

    presenter = ProtectedAreaPresenter.new(pa)

    assert_equal 33.33, presenter.percentage_complete.round(2)
  end
end
