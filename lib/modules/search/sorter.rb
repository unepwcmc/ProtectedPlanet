class Search::Sorter
  SORTERS = {
    geo_distance: { type: 'geo_distance', field: 'protected_area.coordinates' },
    datetime: { type: 'datetime' }
  }

  def initialize term, options
    @options = options
    @term = term
  end

  def to_h
    sorter.to_h
  end

  def self.from_params params
    constructed_sorters = []

    params.each do |name, value|
      constructed_sorters.push self.new(
        value, SORTERS[name.to_sym]
      ).to_h
    end

    constructed_sorters
  end

  private

  def sorter
    sorter_type  = @options[:type].classify
    sorter_class = "Search::Sorter::#{sorter_type}".constantize

    sorter_class.new @term, @options
  end
end
