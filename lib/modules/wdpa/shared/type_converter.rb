# frozen_string_literal: true

module Wdpa::Shared
  class TypeConverter
    TYPE_CONVERSIONS = {
      geometry: ->(value) { RGeo::WKRep::WKBParser.new.parse(value).to_s },
      # Need to match the number 2 as well as this is used as marine type
      boolean: ->(value) { !value.match(/^(true|t|1|2)$/i).nil? },
      oecm: ->(value) { !value.match(/^0$/i).nil? },
      oecm_string: ->(value) { !value.match(/^oecm$/i).nil? },
      integer: ->(value) { value.to_i },
      string: ->(value) { value.to_s },
      float: ->(value) { value.to_f },
      csv: ->(value) { value.present? ? value.split(';').map(&:strip) : [] },
      year: lambda { |value|
        value = value.to_s
        return nil if value.to_i.zero?

        Date.strptime(value, '%Y')
      },
      gl_expiry_date: lambda { |value|
        # gl_expiry was a date column in the database but now as of 19Mar2026 
        # NC team decided to store only 4 digits year in DMP
        # so we store it as last day of the year yyyy-12-31 but display it as YYYY in the frontend
        # We do this in case they decide to store the date again in the future, 
        # we can easily change the code here and greenlist_status_by_pa_and_all_its_parcels method.
        begin
          return nil if value.blank?
          return value if value.is_a?(Date)

          value = value.to_s.strip
          return nil if value.blank?

          # incoming value should be YYYY
          if value.match?(/\A\d{4}\z/)
            Date.strptime("#{value}-12-31", '%Y-%m-%d')
          elsif value.match?(/\A\d{8}\z/)
            Date.strptime(value, '%Y%m%d')
          else
            Date.parse(value)
          end
        rescue ArgumentError
          nil
        end
      }
    }.freeze

    def self.convert(value, as:)
      type = as

      raise NotImplementedError, "No conversion exists for type '#{type}'" if TYPE_CONVERSIONS[type].nil?

      TYPE_CONVERSIONS[type].call(value)
    end
  end
end
