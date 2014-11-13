class SavedSearch < ActiveRecord::Base
  belongs_to :project
  accepts_nested_attributes_for :project

  def self.create_and_populate params
    self.create!(params).tap{ |saved_search|
      SearchWorkers::ResultsPopulator.perform_async(saved_search.id)
    }
  end

  def name
    search_term
  end

  def parsed_filters
    JSON.parse(filters) if filters.present?
  end

  def wdpa_ids
    results_ids.map(&:to_i)
  end

  def generation_info
    generation_status = $redis.get("saved_searches:#{id}:all")
    SearchWorkers::ResultsPopulator.perform_async id if generation_status.nil?

    JSON.parse(generation_status) rescue {}
  end

  def population_completed?
    generation_info['status'] == 'completed'
  end
end
