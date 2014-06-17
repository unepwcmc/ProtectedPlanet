require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest

  test "renders the Protected Area name" do
    protected_area = FactoryGirl.create(:protected_area, name: 'Killbear', slug: 'killbear')

    get '/killbear'
    assert_match /Killbear/, @response.body
  end

  test 'renders the Protected Area name given a WDPA ID' do
    protected_area = FactoryGirl.create(:protected_area, wdpa_id: 1234, name: 'Killbear')

    get '/1234'
    assert_match /Killbear/, @response.body
  end

  test 'renders the Images for the Protected Area' do
    image = FactoryGirl.create(:image, url: 'http://images.com/image.jpg')
    FactoryGirl.create(:protected_area, wdpa_id: 1234, images: [image])

    get '/1234'

    assert_select 'ul.protected_area_photos' do
      assert_select 'li', 1 do |elements|
        elements.each do |element|
          assert_select element, 'img'
        end
      end
    end
  end
end
