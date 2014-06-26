require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest
  def setup
    @region  = FactoryGirl.create(:region, name: 'Killbeurope')
    @country = FactoryGirl.create(:country, name: 'Killbearland', region: @region)
    @protected_area = FactoryGirl.create(
      :protected_area, name: 'Killbear', slug: 'killbear', countries: [@country]
    )
  end

  test 'renders the Protected Area name' do
    get "/#{@protected_area.slug}"
    assert_match /Killbear/, @response.body
  end

  test 'renders the Protected Area name given a WDPA ID' do
    get "/#{@protected_area.wdpa_id}"
    assert_match /Killbear/, @response.body
  end

  test 'renders the Wikipedia summary' do
    wikipedia_article = FactoryGirl.create(
      :wikipedia_article,
      summary: 'Summary text',
      image_url: 'http://url.com/image.jpg',
      url: 'http://url.com/article',
      protected_area: @protected_area
    )

    get "/#{@protected_area.slug}"
    assert_match Regexp.new(wikipedia_article.summary), @response.body
    assert_match Regexp.new(wikipedia_article.url), @response.body
  end

  test 'renders the Images for the Protected Area' do
    image = FactoryGirl.create(:image, url: 'http://images.com/image.jpg')
    @protected_area = FactoryGirl.create(
      :protected_area, countries: [@country], images: [image]
    )

    get "/#{@protected_area.wdpa_id}"

    assert_select 'ul.protected-area-photos' do
      assert_select 'li', 1 do |elements|
        elements.each do |element|
          assert_select element, 'img'
        end
      end
    end
  end
end
