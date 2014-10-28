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
    :wkb_geometry => {name: :the_geom, type: :geometry},
    :metadataid   => {name: :sources, type: :integer}
  }

  POLYGON_ATTRIBUTES = [
    :gis_m_area,
    :gis_area,
    :shape_area,
    :shape_length
  ]

  module Matchers
    GEOMETRY_TABLE = /wdpa_?po/i
    POLYGON_TABLE  = /poly/i
    SOURCE_TABLE   = /wdpa_?source/i
  end

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

  def self.common_attributes
    STANDARD_ATTRIBUTES.keys - POLYGON_ATTRIBUTES
  end

  def self.standard_geometry_attributes
    standard_attributes.select do |key, hash|
      Array.wrap(standard_attributes[key]).any? do |attribute|
        attribute[:type] == :geometry
      end
    end
  end

  def self.attributes_from_standards_hash standards_hash
    attributes = standardise_values standards_hash
    attributes = create_models attributes
    attributes = remove_nested_attributes attributes

    attributes
  end

  def self.standardise_table_name table
    if !!(table =~ Matchers::POLYGON_TABLE)
      "standard_polygons"
    else
      "standard_points"
    end
  end

  def self.percentage_complete protected_area
    (fields_with_data(protected_area).count.to_f / STANDARD_ATTRIBUTES.count) * 100
  end

  def self.data_gaps protected_area
    STANDARD_ATTRIBUTES.count - fields_with_data(protected_area).count
  end

  private

  def self.fields_with_data protected_area
    STANDARD_ATTRIBUTES.values.select do |attribute|
      protected_area.try(attribute[:name]).present?
    end
  end

  def self.standardise_values hash
    standardised_attributes = {}

    hash.each do |key, value|
      attributes = Array.wrap(self::STANDARD_ATTRIBUTES[key])
      attributes.each do |attribute|
        standardised_value = Wdpa::Attribute.standardise value, as: attribute[:type]
        standardised_attributes[attribute[:name]] = standardised_value
      end
    end

    standardised_attributes
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
