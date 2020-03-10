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
      options[:size] = params['items_per_page'].to_i if params['items_per_page'].present?
      options
    end

    def search_index
      controller_name.include?('area') ? Search::AREAS_INDEX_NAME : Search::DEFAULT_INDEX_NAME
    end

    AREA_TYPES = %w(wdpa oecm).freeze
    def check_area_type
      redirect_to :root unless AREA_TYPES.include?(params[:area_type].downcase)
    end

    def filters
      return '' unless params['filters'].present?
      _filters = sanitise_filters
      _filters.symbolize_keys.slice(*Search::ALLOWED_FILTERS)
    end

    def sanitise_filters
      _filters = JSON.parse(params['filters'])
      #TODO green list filter to be added
      is_type = _filters.delete('is_type')
      return _filters if is_type == 'all' || !is_type

      _filters[:marine] = is_type == 'marine'

      _filters
    end
  end
end
