class WikipediaArticle < ActiveRecord::Base
  attr_accessor :title
  has_one :protected_area

  def self.search title
    query = {
      action: 'query',
      list: 'search',
      format: 'json',
      srsearch: title
    }

    response = HTTParty.get(Rails.application.secrets.wikipedia_api_url, {query: query})
    article_list = JSON.parse(response.body)['query']['search']

    article_list.map{|article| WikipediaArticle.new(title: article['title'])}
  end
end
