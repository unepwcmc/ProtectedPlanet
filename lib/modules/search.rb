class Search
  def self.search search_term
    instance = self.new search_term
    instance.search

    instance
  end

  def initialize search_term
    @search_term = search_term
  end

  def search
    @query_results ||= elastic_search.search(index: 'protected_areas', body: query)
  end

  def results
    matches = @query_results["hits"]["hits"]

    @matches ||= matches.map do |result|
      model_class = result["_type"].classify.constantize
      model_class.find(result["_source"]["id"])
    end
  end

  def aggregations
    aggs_by_model = {}

    @query_results["aggregations"].each do |name, aggs|
      model = name.classify.constantize

      aggs_by_model[name] = aggs["aggregation"]["buckets"].map do |info|
        {
          model: model.find(info["key"]),
          count: info["doc_count"]
        }
      end
    end

    aggs_by_model
  end

  private

  def elastic_search
    @elastic_search ||= Elasticsearch::Client.new
  end

  def query
    {
      size: 10,
      query: Search::Query.new(@search_term).to_h,
      aggs: Search::Aggregation.all
    }
  end
end
