class Wdpa::Attribute
  TYPE_CONVERSIONS = {
    geometry: -> (value) { RGeo::WKRep::WKBParser.new.parse(value).to_s },
    boolean:  -> (value) { value.match(/^(true|t|1)$/i) != nil },
    integer:  -> (value) { value.to_i },
    string:   -> (value) { value.to_s },
    float:    -> (value) { value.to_f },
    csv:      -> (value) { value.split(',').map(&:strip) },
    year:     -> (value) {
      value = value.to_s
      # Postgres cannot handle zero dates, and the WDPA stores
      # null legal statuses as zeroes
      value = '1' if value == '0'

      Date.strptime(value, '%Y')
    }
  }

  def self.standardise(value, as:)
    type = as

    if TYPE_CONVERSIONS[type].nil?
      raise NotImplementedError, "No conversion exists for type '#{type}'"
    end

    TYPE_CONVERSIONS[type].call(value)
  end
end
