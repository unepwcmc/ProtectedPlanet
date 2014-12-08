class Search
  include ActiveToken
  token_domain 'search'

  ALLOWED_FILTERS = [:type, :country, :iucn_category, :designation, :region, :marine]

  attr_reader :search_term, :options

  def self.search search_term, options={}
    instance = self.new search_term, options
    instance.search

    instance
  end

  def self.download search_term, options={}
    token = Digest::SHA256.hexdigest(
      (search_term || "") + Marshal.dump(
        options.keys.sort.map{|key| options[key]}
      )
    )

    find(token, search_term, options) || begin
      instance = create(token, search_term, options)
      SearchWorkers::Downloader.perform_async(token, search_term, options)
      instance
    end
  end

  def initialize search_term='', options={}
    self.search_term = search_term
    self.options = options
  end

  def search
    @query_results ||= elastic_search.search(index: 'protected_areas', body: query)
  end

  def results
    @results ||= Search::Results.new(@query_results)
  end

  def complete!
    properties['status'] = 'completed'
  end


  def aggregations
    aggs_by_model = {}

    @query_results['aggregations'].each do |name, aggs|
      model = name.classify.constantize

      aggs_by_model[name] = aggs['aggregation']['buckets'].map do |info|
        {
          model: (model.without_geometry.find(info['key']) rescue model.find(info['key'])),
          count: info['doc_count']
        }
      end
    end

    aggs_by_model
  end

  def current_page
    options[:page] || 1
  end

  def total_pages
    results.count / RESULTS_SIZE
  end

  private
  attr_writer :search_term, :options

  RESULTS_SIZE = 20

  def elastic_search
    @elastic_search ||= Elasticsearch::Client.new(
      url: Rails.application.secrets.elasticsearch['url']
    )
  end

  def query
    {
      size: options[:size] || RESULTS_SIZE,
      from: options[:offset] || offset,
      query: Search::Query.new(search_term, options).to_h,
    }.tap do |query|
      unless options[:without_aggregations]
        query[:aggs] = Search::Aggregation.all
      end

      if options[:sort].present?
        query[:sort] = Search::Sorter.from_params(options[:sort])
      end
    end
  end

  def offset
    RESULTS_SIZE * (current_page - 1)
  end
end
