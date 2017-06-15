class SavedSearch < ActiveRecord::Base
  def name
    search_term
  end

  def parsed_filters
    JSON.parse(filters) if filters.present?
  end

  def wdpa_ids
    search.results.pluck('wdpa_id')
  end

  private

  def search
    @search ||= Search.search(search_term, {
      filters: {'type' => 'protected_area'}.merge(parsed_filters || {}),
      without_aggregations: true
    })
  end
end
