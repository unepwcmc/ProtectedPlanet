require 'test_helper'

class WikipediaArticleTest < ActiveSupport::TestCase
  test '#search returns an array of WikipediaArticle instances' do 
    query = {
      action: 'query',
      list: 'search',
      format: 'json',
      srsearch: 'algonquin'
    }

    wikipedia_article_json = { "query" => {
      "search" => [{
        "ns" => 0,
        "size" => 2819,
        "snippet" => "<span class='searchmatch'>Algonquin</span> or Algonquian\u2014and the variation Algonki(a)n\u2014may refer to: Native Americans : Algonquian languages , a large subfamily of Native  <b>...</b> ",
        "timestamp" => "2014-05-03T01:57:01Z",
        "title" => "Algonquin",
        "wordcount" => 316
      }]
    }}.to_json

    stub_request(:get, 'http://en.wikipedia.org/w/api.php').
      with({query: query}).
      to_return(status: 200, body: wikipedia_article_json)

    results = WikipediaArticle.search 'algonquin'

    assert_not_nil results, "Expected #search to return results"
    assert_equal   1, results.count

    article = results.first

    assert_kind_of WikipediaArticle, article
    assert_equal   'Algonquin', article.title
  end
end
