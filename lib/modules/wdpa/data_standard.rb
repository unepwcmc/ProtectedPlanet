class Wdpa::DataStandard
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
    :status_yr  => {name: :legal_status_updated_at, type: :year},
    :iucn_cat   => {name: :iucn_category, type: :string},
    :gov_type   => {name: :governance, type: :string},
    :mang_auth  => {name: :management_authority, type: :string},
    :mang_plan  => {name: :management_plan, type: :string},
    :int_crit   => {name: :international_criteria, type: :string},
    :no_take    => {name: :no_take, type: :string},
    :no_tk_area => {name: :no_take_area, type: :float},
    :desig      => {name: :designation, type: :string},
    :desig_type => {name: :jurisdiction, type: :string}
  }

  NESTED_ATTRIBUTES = [
    :jurisdiction,
    :no_take_area
  ]

  def self.attributes_from_standards_hash standards_hash
    standardised_attributes = {}
    standards_hash.each do |key, value|
      attribute = STANDARD_ATTRIBUTES[key]
      unless attribute.nil?
        standardised_value = Wdpa::Attribute.standardise value, as: attribute[:type]
        standardised_attributes[attribute[:name]] = standardised_value
      end
    end

    standardised_attributes.each do |key, value|
      relation = Wdpa::Relation.new standardised_attributes
      relational_value = relation.create(key, value)

      standardised_attributes[key] = relational_value
    end

    NESTED_ATTRIBUTES.each do |attribute|
      standardised_attributes.delete attribute
    end

    return standardised_attributes
  end
end
