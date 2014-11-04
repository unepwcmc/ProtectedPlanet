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

  test '#protected_area_cover, given a pa, returns an image tag to the asset controller' do
    pa = FactoryGirl.create(:protected_area, name: "Manbone")
    expected_tag = %Q{<img alt="Manbone" src="/assets/tiles/#{pa.id}?size%5Bx%5D=256&amp;size%5By%5D=128" style="width: 256px; height: 128px" />}


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
