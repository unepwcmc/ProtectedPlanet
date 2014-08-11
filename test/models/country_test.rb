require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  test '.bounds returns the bounding box for the Country geometry' do
    country = FactoryGirl.create(:country, bounding_box: 'POLYGON ((-1 0, 0 1, 1 2, 1 0, -1 0))')

    assert_equal [[0, -1], [2, 1]], country.bounds
  end

  test '.without_geometry does not select the geometry columns' do
    country = FactoryGirl.create(:country)

    selected_country = Country.without_geometry.find(country.id)

    refute selected_country.has_attribute?(:bounding_box)
  end

  test '.as_indexed_json returns the Country as JSON' do
    region = FactoryGirl.create(:region, id: 987, name: 'North Manmerica')
    country = FactoryGirl.create(:country, id: 123, name: 'Manboneland', region: region)

    expected_json = {
      "id" => 123,
      "name" => 'Manboneland',
      "region" => {
        "id" => 987,
        "name" => "North Manmerica"
      }
    }

    assert_equal expected_json, country.as_indexed_json
  end
end
