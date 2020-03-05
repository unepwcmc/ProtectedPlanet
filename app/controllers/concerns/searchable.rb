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
      return _filters unless _filters['is_type']

      is_type = _filters.delete('is_type')
      terrestrial = is_type.include?('Terrestrial')
      marine = is_type.include?('Marine')

      # TODO Not ideal. It would be good to have seperate filters for these
      # The way this works now is the following:
      # - both marine and terrestial unselected will return all areas (otherwise always returns empty results)
      # - both marine and terrestrial selected will return all areas
      # - only marine selected will return only marine areas
      # - only terrestrial selected will return only terrestrial areas
      # - green-list selected returns only green-listed areas regardless of marine/terrestrial
      # - green-list unselected returns only non green-listed areas regardless of marine/terrestrial

      _filters[:marine] = true if marine && !terrestrial
      _filters[:marine] = false if terrestrial && !marine

      _filters[:is_green_list] = is_type.include?('Green List')

      _filters
    end
  end
end
