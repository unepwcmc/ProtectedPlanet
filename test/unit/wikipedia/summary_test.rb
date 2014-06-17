require 'test_helper'

class WikipediaSummaryTest < ActiveSupport::TestCase
  test '#fetch returns the summary for a WikipediaArticle' do
    query = {
      action: 'query',
      prop: 'extracts',
      exintro: '',
      format: 'json',
      titles: 'Algonquin'
    }

    expected_summary = 'I am afraid I no longer understand modern day www.'

    wikipedia_article_json = { "query" => {
      "pages" => {
        "18831" => {
          "extract" => expected_summary,
          "ns" => 0,
          "pageid" => 18831,
          "title" => "Mathematics"
        }
      }
    }}.to_json

    stub_request(:get, 'http://en.wikipedia.org/w/api.php').
      with({query: query}).
      to_return(status: 200, body: wikipedia_article_json)

    wikipedia_article = FactoryGirl.create(:wikipedia_article, title: 'Algonquin')
    summary = Wikipedia::Summary.fetch wikipedia_article

    assert_not_nil summary, "Expected #fetch to return a summary"
    assert_equal   expected_summary, summary
  end
end
