require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test '.commaify delimits the given number with commas' do
    assert_equal "22,123,456", commaify(22123456)
    assert_equal "22,123,456", commaify("22123456")
  end

  test '#protected_area_cover returns the tiles path for the pa' do
    pa = FactoryBot.create(:protected_area, name: "Manbone")

    assert_equal "/assets/tiles/#{pa.site_id}?type=protected_area&version=1",
                 protected_area_cover(pa)
  end

  test '#country_cover returns the tiles path for the country' do
    country = FactoryBot.create(:country, iso: "MBO", name: 'Country')

    assert_equal "/assets/tiles/#{country.iso}?type=country&version=1",
                 country_cover(country)
  end

  test '#region_cover returns the tiles path for the region' do
    region = FactoryBot.create(:region, iso: "MBO", name: 'region')

    assert_equal "/assets/tiles/#{region.iso}?type=region&version=1",
                 region_cover(region)
  end
end
