require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest

  test 'renders the Protected Area name' do
    FactoryGirl.create(:protected_area, name: 'Killbear', slug: 'killbear')

    get '/killbear'
    assert_match /Killbear/, @response.body
  end

  test 'renders the Protected Area name given a WDPA ID' do
    FactoryGirl.create(:protected_area, wdpa_id: 1234, name: 'Killbear')

    get '/1234'
    assert_match /Killbear/, @response.body
  end

  test 'renders the Wikipedia summary' do
    protected_area = FactoryGirl.create(:protected_area, slug: 'killbear')
    wikipedia_article = FactoryGirl.create(
      :wikipedia_article,
      summary: 'Summary text',
      image_url: 'http://url.com/image.jpg',
      url: 'http://url.com/article',
      protected_area: protected_area
    )

    get '/killbear'
    assert_match Regexp.new(wikipedia_article.summary), @response.body
    assert_match Regexp.new(wikipedia_article.image_url), @response.body
    assert_match Regexp.new(wikipedia_article.url), @response.body
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
