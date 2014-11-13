class SearchWorkers::ResultsPopulator < SearchWorkers::Base

  def perform saved_search_id
    @saved_search_id = saved_search_id

    self.search_term = saved_search.search_term
    self.filters = saved_search.parsed_filters

    while_generating { collect_and_save_results }
  end

  private

  def while_generating
    $redis.set("saved_searches:#{@saved_search_id}:all", {status: 'generating'}.to_json)
    yield
    $redis.set("saved_searches:#{@saved_search_id}:all", {status: 'completed'}.to_json)
  end

  def collect_and_save_results
    saved_search.results_ids = protected_area_ids
    saved_search.save
  end

  def saved_search
    @saved_search ||= SavedSearch.find @saved_search_id
  end
end
