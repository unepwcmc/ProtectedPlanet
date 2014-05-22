class Wdpa::Attribute
  TYPE_CONVERSIONS = {
    boolean: Proc.new { |value| value.match(/^(true|t|1)$/i) != nil },
    integer: Proc.new { |value| value.to_i },
    string:  Proc.new { |value| value.to_s },
    float:   Proc.new { |value| value.to_f }
  }

  def self.standardise(value, as:)
    type = as

    if TYPE_CONVERSIONS[type].nil?
      raise NotImplementedError, "No conversion exists for type '#{type}'"
    end

    TYPE_CONVERSIONS[type].call(value)
  end
end
