class Wdpa::Attribute
  TYPE_CONVERSIONS = {
    geometry: -> (value) { RGeo::WKRep::WKBParser.new.parse(value).to_s },
    # Need to match the number 2 as well as this is used as marine type
    boolean:  -> (value) { value.match(/^(true|t|1|2)$/i) != nil },
    oecm:     -> (value) { value.match(/^0$/i) != nil },
    integer:  -> (value) { value.to_i },
    string:   -> (value) { value.to_s },
    float:    -> (value) { value.to_f },
    csv:      -> (value) { value.split(';').map(&:strip) },
    year:     -> (value) {
      value = value.to_s
      # Postgres cannot handle zero dates, and the WDPA stores
      # null legal statuses as zeroes. Also handles 'Not Reported' case
      # and similar
      return nil if value.to_i.zero?

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
