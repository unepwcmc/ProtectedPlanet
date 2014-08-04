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
end
