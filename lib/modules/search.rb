class Search
  CONFIGURATION_FILE = File.read(Rails.root.join('config', 'search.yml')).freeze
  ALLOWED_FILTERS = %i[
    type country iucn_category designation region marine has_irreplaceability_info
    governance ancestor special_status
    is_oecm topic page_type
  ].freeze
  COUNTRY_INDEX = "countries_#{Rails.env}".freeze
  REGION_INDEX = "regions_#{Rails.env}".freeze
  PA_INDEX = "protectedareas_#{Rails.env}".freeze
  CMS_INDEX = "cms_#{Rails.env}".freeze
  AREAS_INDEX = [PA_INDEX, COUNTRY_INDEX, REGION_INDEX].join(',').freeze
  COUNTRY_REGION_INDEX = [COUNTRY_INDEX, REGION_INDEX].join(',').freeze
  DEFAULT_INDEX_NAME = "#{AREAS_INDEX},#{CMS_INDEX}".freeze
  attr_reader :search_term, :options

  def self.configuration
    @@configuration ||= YAML.load(CONFIGURATION_FILE)
  end

  def self.search(search_term, options = {}, index_name = DEFAULT_INDEX_NAME)
    # after receiving some crazy long search terms that crash elasticsearch
    # we are limiting this to 128 characters
    instance = new (search_term.present? ? search_term[0..127] : search_term), options, index_name
    instance.search

    instance
  end

  def initialize search_term = '', options, index_name
    self.search_term = search_term
    self.options = options
    @index_name = index_name
  end

  def search
    @query_results ||= fetch_query_results
  rescue Faraday::TimeoutError => e
    Rails.logger.warn 'timeout in search'
    Rails.logger.warn e
    @query_results ||= { 'hits' => { 'total' => 0, 'hits' => [] } }
  end

  # Cache the Elasticsearch response for searches with no search term.
  #
  # WHY: `optional_queries` attaches Search::Aggregation.all to every query -- nine
  # aggregations, six of them `nested`
  # (lib/modules/search/templates/aggregations.json). With a search term those run
  # over the handful of matched documents and the request costs ~1.2s. With no term
  # there is nothing to narrow the document set, so they run across the whole index
  # (~317k protected areas) and the request costs seconds. Measured by the
  # post-deploy route walk against staging:
  #
  #   /en/search-areas                        6497ms
  #   /en/search-areas-results                8326ms
  #   /en/search-areas-results?search_term=park 1208ms
  #
  # The aggregations cannot simply be dropped: `search_areas#index` feeds them to
  # Search::FiltersSerializer to build the filter panel, and AreasSerializer#sites
  # reads aggregations['governance'] for its total count.
  #
  # WHY ONLY BLANK TERMS: they are the expensive ones, they are identical for every
  # visitor, and their number is bounded by the filter combinations. Caching typed
  # terms would let any visitor grow the cache without limit, for queries that are
  # already fast.
  #
  # Staleness is bounded by the TTL, and .kamal/hooks/post-deploy clears Rails.cache
  # on every deploy, so shipping new data clears these entries too. This matters
  # more since the move to `expires_in 0, must_revalidate` on the page itself --
  # these responses are no longer sitting in Rack::Cache.
  SEARCH_CACHE_TTL = 1.hour

  def fetch_query_results
    return run_query unless cache_query_results?

    Rails.cache.fetch(query_results_cache_key, expires_in: SEARCH_CACHE_TTL) { run_query }
  end

  def run_query
    elastic_search.search(index: @index_name, body: query)
  end

  def cache_query_results?
    search_term.blank?
  end

  def query_results_cache_key
    # The body carries everything that changes the result -- filters, paging, sort,
    # and whether aggregations were asked for -- so digesting it is enough. The index
    # name is separate because the same body is valid against several indices.
    ['search', @index_name, Digest::SHA256.hexdigest(query.to_json)].join('/')
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

  def page_items_start(page: 1, per_page: RESULTS_SIZE, for_display: false)
    n = (page - 1) * per_page
    for_display ? n + 1 : n
  end

  def page_items_end(page: 1, per_page: RESULTS_SIZE, for_display: false)
    n = page * per_page - 1
    if for_display
      n >= results.count ? results.count : n + 1
    else
      n
    end
  end

  attr_writer :search_term, :options

  RESULTS_SIZE = 20.0

  def elastic_search
    @elastic_search ||= Elasticsearch::Client.new(
      url: AppSecrets.elasticsearch.url
    )
  end

  def query
    size = options[:size] || RESULTS_SIZE
    {
      size: size,
      from: options[:offset] || offset(size),

      # This line helps countries come first in search, may need tweaking as initial weights are dependent on the relative
      # frequency of terms in the countries and PA indices which is hard to anticipate!
      indices_boost: [{ COUNTRY_INDEX => 5 }, { PA_INDEX => 1 }],
      query: Search::Query.new(search_term, options).to_h
    }.tap(&method(:optional_queries))
  end

  def optional_queries(query)
    query[:aggs] = Search::Aggregation.all unless options[:without_aggregations]

    if options[:sort].present?
      query[:sort] = Search::Sorter.from_params(options[:sort])
    end

    if options[:last_site_id].present?
      query[:search_after] = [options[:last_site_id]]
    end
  end

  def offset(size = RESULTS_SIZE)
    size * (current_page - 1)
  end
end
