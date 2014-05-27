class WdpaDataStandard
  STANDARD_ATTRIBUTES = {
    :wdpaid     => {name: :wdpa_id, type: :integer},
    :wdpa_pid   => {name: :wdpa_parent_id, type: :integer},
    :name       => {name: :name, type: :string},
    :orig_name  => {name: :original_name, type: :string},
    :marine     => {name: :marine, type: :boolean},
    :rep_m_area => {name: :reported_marine_area, type: :float},
    :rep_area   => {name: :reported_area, type: :float},
    :gis_m_area => {name: :gis_marine_area, type: :float},
    :gis_area   => {name: :gis_area, type: :float},
    :iso3       => {name: :countries, type: :csv},
    :sub_loc    => {name: :sub_locations, type: :csv},
    :status     => {name: :legal_status, type: :string},
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

    attributes = create_relations attributes

    return attributes
  end

  private

  def self.create_relations attributes
    attributes.each do |key, value|
      if key == :countries
        attributes[:countries].map! do |country|
          Country.where(iso_3: country).first
        end
      end

      if key == :sub_locations
        attributes[:sub_locations].map! do |sub_location|
          SubLocation.where(iso: sub_location).first
        end
      end

      if key == :legal_status
        attributes[:legal_status] = LegalStatus.where(name: attributes[:legal_status]).first
      end
    end
  end
end
