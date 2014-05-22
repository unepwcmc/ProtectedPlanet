class WdpaDataStandard
  STANDARD_ATTRIBUTES = {
    :wdpaid => {name: :wdpa_id, type: :integer},
    :wdpa_pid => {name: :wdpa_parent_id, type: :integer},
    :name => {name: :name, type: :string},
    :orig_name => {name: :original_name, type: :string},
    :marine => {name: :marine, type: :boolean}
  }

  def self.attributes_from_standards_hash standards_hash
    attributes = {}

    standards_hash.each do |key, value|
      attribute = STANDARD_ATTRIBUTES[key]
      unless attribute.nil?
        standardised_value = Wdpa::Attribute.standardise value, as: attribute[:type]
        attributes[attribute[:name]] = standardised_value
      end
    end

    return attributes
  end
end
