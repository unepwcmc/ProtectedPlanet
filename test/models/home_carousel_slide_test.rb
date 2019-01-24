require_relative '../test_helper'

class HomeCarouselSlideTest < ActiveSupport::TestCase

  def test_fixtures_validity
    HomeCarouselSlide.all.each do |home_carousel_slide|
      assert home_carousel_slide.valid?, home_carousel_slide.errors.inspect
    end
  end

  def test_validation
    home_carousel_slide = HomeCarouselSlide.new
    assert home_carousel_slide.invalid?
    assert_errors_on home_carousel_slide, :title, :description, :url
  end

  def test_creation
    assert_difference 'HomeCarouselSlide.count' do
      HomeCarouselSlide.create(
        :title => 'test title',
        :description => 'test description',
        :url => 'test url',
      )
    end
  end

end