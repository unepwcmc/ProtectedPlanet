# Only used for the areas search download - to cache search results and reduce
# performance hit on the system
class SavedSearch < ApplicationRecord
  # Elasticsearch has a maximum page size of 10000
  MAX_SIZE = 9999

  def name
    search_term
  end

  def parsed_filters
    JSON.parse(filters) if filters.present?
  end

  def all_site_ids
    search_results.flatten
  end

  private

  def search_results
    # Perform initial search to store the first set of results 
    @results = []

    initial_set = extract_site_ids(download_search.results)

    @results << initial_set

    # Return early if number of hits is less than 10000 to avoid unnecessary searches
    return @results if @results.last.length < MAX_SIZE

    # Keep looping until there are no more results
    loop do 
      last_site_id = @results.last.last

      next_batch = extract_site_ids(download_search(last_site_id).results)

      break if next_batch.empty?

      @results << next_batch
    end

    @results
  end

  def extract_site_ids(results)
    results.pluck('site_id')
  end 

  def search_query_options
    {
      offset: 0, # Have to set this to 0 for Elastic's search_after API
      filters: parsed_filters || {},
      without_aggregations: true,
      sort: [{ 'site_id': 'asc' }],
      size: MAX_SIZE
    }
  end

  # Make use of Elasticsearch search_after API to search after the SITE ID passed
  # to the search. 
  def download_search(last_site_id_of_results = nil)
    if last_site_id_of_results
      merged_query_options = search_query_options.merge({ last_site_id: last_site_id_of_results })
    else 
      merged_query_options = search_query_options
    end

    Search.search(search_term, merged_query_options, Search::PA_INDEX)
  end
end
