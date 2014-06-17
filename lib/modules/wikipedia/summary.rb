class Wikipedia::Summary
  def self.fetch wikipedia_article
    query = {
      action: 'query',
      prop: 'extracts',
      exintro: '',
      format: 'json',
      titles: wikipedia_article.title
    }

    response = HTTParty.get(Rails.application.secrets.wikipedia_api_url, {query: query})
    _, article = JSON.parse(response.body)['query']['pages'].first

    article['extract']
  end
end
