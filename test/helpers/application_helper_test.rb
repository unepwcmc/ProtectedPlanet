require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test '.commaify delimits the given number with commas' do
    assert_equal "22,123,456", commaify(22123456)
    assert_equal "22,123,456", commaify("22123456")
  end

  test '#cover, given a pa, returns an image tag to the asset controller' do
    pa = FactoryGirl.create(:protected_area, name: "Manbone")
    expected_tag = %Q{<img alt="Manbone" class="image" data-src="/assets/tiles/#{pa.site_id}?type=protected_area&amp;version=1" data-error="/images/search-placeholder-country.png" data-loading="/images/search-placeholder-country.png" src="/images/search-placeholder-country.png" />}

    tag = cover(pa)
    assert_equal expected_tag, tag
  end

  test '#cover, given a country, returns the image tag for an image of the country' do
    country = FactoryGirl.create(:country, iso: "MBO", name: 'Country')

    expected_tag = %Q{<img alt="Country" data-src="/assets/tiles/#{country.iso}?type=country&amp;version=1" data-error="/images/search-placeholder-country.png" data-loading="/images/search-placeholder-country.png" src="/images/search-placeholder-country.png" />}
    tag = cover(country)

    assert_equal expected_tag, tag
  end

  test '#cover, given a region, returns the image tag
   for an image of the region' do
    region = FactoryGirl.create(:region, iso: "MBO", name: 'region')

    expected_tag = '<img alt="region" src="/images/search-placeholder-region.png" />'
    tag = cover(region)

    assert_equal expected_tag, tag
  end
end
