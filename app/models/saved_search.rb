class SavedSearch < ActiveRecord::Base
  belongs_to :project
  accepts_nested_attributes_for :project

  def name
    search_term
  end

  def parsed_filters
    JSON.parse(filters) if filters.present?
  end

  def wdpa_ids
    search.pluck('wdpa_id')
  end

  private

  def search
    @search ||= Search.search(search_term, {
      filters: {'type' => 'protected_area'}.merge(parsed_filters || {}),
      size: ProtectedArea.count,
      without_aggregations: true
    })
  end
end
