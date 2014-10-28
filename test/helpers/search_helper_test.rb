require 'test_helper'

class SearchHelperTest < ActionView::TestCase
  test '#type_li_tag, given a type and the selected type, returns an li
   tag with a selected class if the given type matches selected type' do
    selected_class = type_li_tag('country', 'country') { "inner text" }
    assert_equal '<li class="selected">inner text</li>', selected_class
  end

  test '#type_li_tag, given a type and the selected type, returns an li
   tag without a selected class if the given type does not match
   selected type' do
    selected_class = type_li_tag('protected_area', 'country') { "inner text" }
    assert_equal '<li class="">inner text</li>', selected_class
  end

  test '#link_to_search, given params and a filter, returns a link to
   the current search with the new filter' do
    params = {
      query: 'test',
      type: 'country'
    }

    model = FactoryGirl.create(:country, name: 'Manbone', id: 123)

    facet = {
      model: model,
      count: 4
    }

    expected_link = "<a href=\"/search?country=123&amp;query=test&amp;type=country\">Manbone (4)</a>"
    link = facet_link facet, params

    assert_equal expected_link, link
  end

  test '#protected_area_cover, given a pa with an image, returns the image tag
   for an image of the pa' do
    image = FactoryGirl.create(:image, url: 'http://hey.com/img.bmp')

    pa = FactoryGirl.create(:protected_area,
      name: "Manbone",
      images: [image]
    )

    expected_tag = '<img alt="Manbone" src="http://hey.com/img.bmp" style="width: 256px; height: 128px" />'
    tag = protected_area_cover(pa)

    assert_equal expected_tag, tag
  end

  test '#protected_area_cover, given a pa without an image, returns map of the
   PA' do
    pa = FactoryGirl.create(:protected_area,
      name: "Manbone",
      the_geom: 'POINT(1 0)',
      the_geom_latitude: 1,
      the_geom_longitude: 0
    )
    expected_tag = '<img alt="Manbone" '
    expected_tag << 'src="http://mapbox.com/geojson({&quot;type&quot;:&quot;Point&quot;,&quot;coordinates&quot;:[1,0]})'
    expected_tag << '/auto/256x128.png?access_token=123" style="width: 256px; height: 128px" />'

    Rails.application.secrets.stubs(:mapbox).returns({'access_token' => '123', 'base_url' => 'http://mapbox.com/'})
    tag = protected_area_cover(pa)

    assert_equal expected_tag, tag
  end

  test '#country_cover, given a country, returns the image tag
   for an image of the country' do
    country = FactoryGirl.create(:country, iso: "MBO", name: 'Country')

    expected_tag = '<img alt="Country" src="/images/countries/MBO.png" style="width: 256px; height: 128px" />'
    tag = country_cover(country)

    assert_equal expected_tag, tag
  end

  test '#region_cover, given a region, returns the image tag
   for an image of the region' do
    region = FactoryGirl.create(:region, iso: "MBO", name: 'region')

    expected_tag = '<img alt="region" src="/images/regions/MBO.png" style="width: 256px; height: 128px" />'
    tag = region_cover(region)

    assert_equal expected_tag, tag
  end
end
