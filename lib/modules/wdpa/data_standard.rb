class Wdpa::DataStandard
  STANDARD_ATTRIBUTES = {
    :wdpaid       => {name: :wdpa_id, type: :integer},
    :wdpa_pid     => {name: :wdpa_parent_id, type: :integer},
    :name         => {name: :name, type: :string},
    :orig_name    => {name: :original_name, type: :string},
    :marine       => {name: :marine, type: :boolean},
    :rep_m_area   => {name: :reported_marine_area, type: :float},
    :rep_area     => {name: :reported_area, type: :float},
    :gis_m_area   => {name: :gis_marine_area, type: :float},
    :gis_area     => {name: :gis_area, type: :float},
    :iso3         => {name: :countries, type: :csv},
    :sub_loc      => {name: :sub_locations, type: :csv},
    :status       => {name: :legal_status, type: :string},
    :status_yr    => {name: :legal_status_updated_at, type: :year},
    :iucn_cat     => {name: :iucn_category, type: :string},
    :gov_type     => {name: :governance, type: :string},
    :mang_auth    => {name: :management_authority, type: :string},
    :mang_plan    => {name: :management_plan, type: :string},
    :int_crit     => {name: :international_criteria, type: :string},
    :no_take      => {name: :no_take_status, type: :string},
    :no_tk_area   => {name: :no_take_area, type: :float},
    :desig        => {name: :designation, type: :string},
    :desig_type   => {name: :jurisdiction, type: :string},
    :wkb_geometry => {name: :the_geom, type: :geometry}
  }

  #
  # Attributes that are only used in combination with other attributes,
  # and have no matching attribute on ProtectedArea
  #
  NESTED_ATTRIBUTES = [
    :jurisdiction,
    :no_take_area
  ]

  def self.standard_attributes
    STANDARD_ATTRIBUTES
  end

  def self.standard_geometry_attributes
    standard_attributes.select do |key, hash|
      standard_attributes[key][:type] == :geometry
    end
  end

  def self.attributes_from_standards_hash standards_hash
    attributes = standardise_values standards_hash
    attributes = create_models attributes
    attributes = remove_nested_attributes attributes

    attributes
  end

  private

  def self.standardise_values hash
    attributes = {}

    hash.each do |key, value|
      attribute = STANDARD_ATTRIBUTES[key]
      unless attribute.nil?
        standardised_value = Wdpa::Attribute.standardise value, as: attribute[:type]
        attributes[attribute[:name]] = standardised_value
      end
    end

    attributes
  end

  def self.create_models hash
    attributes = {}

    hash.each do |key, value|
      relation = Wdpa::Relation.new hash
      relational_value = relation.create(key, value)

      attributes[key] = relational_value
    end

    attributes
  end

  def self.remove_nested_attributes hash
    NESTED_ATTRIBUTES.each do |attribute|
      hash.delete attribute
    end

    hash
  end
end
