require 'test_helper'

class ProtectedAreaShowTest < ActionDispatch::IntegrationTest
  def setup
    @region  = FactoryGirl.create(:region, name: 'Killbeurope')
    @country = FactoryGirl.create(:country, name: 'Killbearland', region: @region)
    @protected_area = FactoryGirl.create(
      :protected_area, name: 'Killbear', slug: 'killbear', countries: [@country]
    )

    search_mock = mock.tap { |m| m.stubs(:results).returns([]) }
    Search.stubs(:search).returns(search_mock)

    seed_cms
  end

  test 'renders the Protected Area name' do
    get "/#{@protected_area.slug}"
    assert_match(/Killbear/, @response.body)
  end

  test 'renders the Protected Area name given a WDPA ID' do
    get "/#{@protected_area.site_id}"
    assert_match(/Killbear/, @response.body)
  end
end
