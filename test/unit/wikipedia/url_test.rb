require 'test_helper'

class WikipediaURLTest < ActiveSupport::TestCase
  test '#build returns the created URL for a WikipediaArticle' do
    wikipedia_article = FactoryGirl.create(:wikipedia_article, title: 'Killbear Antartica')
    expected_url = 'http://en.wikipedia.org/wiki/Killbear_Antartica'

    url = Wikipedia::URL.build wikipedia_article

    assert_equal expected_url, url
  end
end
