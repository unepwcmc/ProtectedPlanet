class Search
  attr_reader :results

  def self.search search_term
    instance = self.new
    instance.search search_term

    instance
  end

  def initialize
    @elastic_search = Elasticsearch::Client.new
    self.results = []
  end

  def search search_term
    body = {size: 10, query: Search::Query.new(search_term).to_h}
    results = @elastic_search.search(index: 'protected_areas', body: body)["hits"]["hits"]

    self.results = results.map do |result|
      model_class = result["_type"].classify.constantize
      model_class.find(result["_source"]["id"])
    end
  end

  private

  attr_writer :results
end
