class SavedSearch < ActiveRecord::Base
  belongs_to :project
  accepts_nested_attributes_for :project

  def self.create_and_populate params
    saved_search = self.create!(params)
    SearchWorkers::ResultsPopulator.perform_async(saved_search.id)
  end

  def name
    search_term
  end

  def parsed_filters
    JSON.parse(filters) if filters.present?
  end

  def wdpa_ids
    results_ids
  end
end
