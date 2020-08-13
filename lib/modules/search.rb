class Search
  CONFIGURATION_FILE = File.read(Rails.root.join('config', 'search.yml')).freeze
  ALLOWED_FILTERS = %i(
    type country iucn_category designation region marine has_irreplaceability_info
    has_parcc_info governance is_green_list is_transboundary category ancestor 
    is_oecm topic page_type
  ).freeze
  COUNTRY_INDEX = "countries_#{Rails.env}".freeze
  REGION_INDEX = "regions_#{Rails.env}".freeze
  PA_INDEX = "protectedareas_#{Rails.env}".freeze
  CMS_INDEX = "cms_#{Rails.env}".freeze
  DEFAULT_INDEX_NAME = [PA_INDEX, CMS_INDEX].join(',').freeze
  AREAS_INDEX_NAME = [PA_INDEX, COUNTRY_INDEX].join(',').freeze
  attr_reader :search_term, :options

  def self.configuration
    @@configuration ||= YAML.load(CONFIGURATION_FILE)
  end

  def self.search search_term, options={}, index_name=DEFAULT_INDEX_NAME
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
      url: Rails.application.secrets.elasticsearch[:url]
    )
  end

  def query
    size = options[:size] || RESULTS_SIZE
    {
      size: size,
      from: options[:offset] || offset(size),
      # This line helps countries come first in search, may need tweaking as initial weights are dependent on the relative
      # frequency of terms in the countries and PA indices which is hard to anticipate!
      indices_boost: [{COUNTRY_INDEX => 3}, {PA_INDEX => 1} ],

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

  def offset(size=RESULTS_SIZE)
    size * (current_page - 1)
  end
end
