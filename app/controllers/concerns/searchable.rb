module Concerns::Searchable
  extend ActiveSupport::Concern

  included do
    private

    def ignore_empty_query
      @query = params['search_term'] rescue nil
      redirect_to :root if @query.blank? && filters.empty?
    end

    def load_search
      begin
        @search = Search.search(@query, search_options, search_index)
      rescue => e
        Rails.logger.warn("error in search controller: #{e.message}")
        @search = nil
      end

      @main_filter = params[:main]
    end

    def search_options
      options = {filters: filters}
      options[:page] = params['requested_page'].to_i if params['requested_page'].present?
      options
    end

    def search_index
      # TODO Define mapping for index between FE and BE
      Search::DEFAULT_INDEX_NAME
    end

    def filters
      params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
    end
  end
end
