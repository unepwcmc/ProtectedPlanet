class Search
  CONFIGURATION_FILE = File.read(Rails.root.join('config', 'search.yml'))
  ALLOWED_FILTERS = [:type, :country, :iucn_category, :designation, :region, :marine, :has_irreplaceability_info, :has_parcc_info, :governance, :is_green_list]

  attr_reader :search_term, :options

  def self.configuration
    @@configuration ||= YAML.load(CONFIGURATION_FILE)
  end

  def self.search search_term, options={}, index_name='protectedareas_test,countries_test'
    # after receiving some crazy long search terms that crash elasticsearch
    # we are limiting this to 128 characters
    instance = self.new (search_term.present? ? search_term[0..127] : search_term), options, index_name
    instance.search

    instance
  end

  def initialize search_term='', options, index_name
    self.search_term = search_term
    self.options = options
    @index_name = index_name
  end

  def search 
#    @query_results ||= elastic_search.search(index: 'protected_areas', body: query)
    @query_results ||= elastic_search.search(index: @index_name, body: query)
  rescue Faraday::TimeoutError => e
    Rails.logger.warn "timeout in search"
    Rails.logger.warn e
    @query_results ||= {"hits" => {"total" => 0, "hits" => []}}
  end

  def results
    @results ||= Search::Results.new(@query_results)
  end

  def aggregations
    Search::Aggregation.parse(@query_results['aggregations'])
  end

  def current_page
    options[:page] || 1
  end

  def total_pages
    (results.count / RESULTS_SIZE).ceil
  end

  private
  attr_writer :search_term, :options

  RESULTS_SIZE = 20.0

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
    }.tap( &method(:optional_queries) )
  end

  def optional_queries query
    unless options[:without_aggregations]
      query[:aggs] = Search::Aggregation.all
    end

    if options[:sort].present?
      query[:sort] = Search::Sorter.from_params(options[:sort])
    end
  end

  def offset
    RESULTS_SIZE * (current_page - 1)
  end
end
