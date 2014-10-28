class SearchWorkers::Base
  include Sidekiq::Worker
  sidekiq_options :retry => false

  attr_accessor :search_term, :token, :filters

  protected

  def search
    @search ||= begin
      instance = Search.search(search_term, {
        filters: {'type' => 'protected_area'}.merge(filters || {}),
        size: ProtectedArea.count,
        without_aggregations: true
      })
      instance.token = token if token.present?
      instance
    end
  end

  def protected_area_ids
    @pa_ids ||= search.pluck('wdpa_id')
  end
end
