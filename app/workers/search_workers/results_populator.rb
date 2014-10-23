class SearchWorkers::ResultsPopulator < SearchWorkers::Base

  def perform saved_search_id
    @saved_search_id = saved_search_id

    self.search_term = saved_search.search_term
    self.filters = saved_search.parsed_filters

    collect_and_save_results
  end

  private

  def collect_and_save_results
    saved_search.results_ids = protected_area_ids
    saved_search.save
  end

  def saved_search
    @saved_search ||= SavedSearch.find @saved_search_id
  end
end
