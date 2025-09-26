class Wdpa::DataStandard
  STANDARD_ATTRIBUTES = {
    :wdpaid       => {name: :wdpa_id, type: :integer, label: 'WDPA ID'},
    # As of 07Apr2025 wdpa_parent_id is not used in the project but it used in ProtectedPlanet-api  
    # see lib/modules/wdpa/protected_area_importer/attribute_importer.rb for more info
    # :wdpa_pid => {name: :wdpa_parent_id, type: :integer, label: 'WDPA Parent ID'},
    :wdpa_pid     => {name: :site_pid, type: :string, label: 'Site Parcel ID'},
    :name         => {name: :name, type: :string, label: 'Name'},
    :orig_name    => {name: :original_name, type: :string, label: 'Original Name'},
    :rep_m_area   => {name: :reported_marine_area, type: :float, label: 'Reported Marine Area'},
    :rep_area     => {name: :reported_area, type: :float, label: 'Reported Area'},
    :gis_m_area   => {name: :gis_marine_area, type: :float, label: 'GIS Marine Area'},
    :gis_area     => {name: :gis_area, type: :float, label: 'GIS Area'},
    :iso3         => {name: :countries, type: :csv, label: 'Country'},
    :sub_loc      => {name: :sub_locations, type: :csv, label: 'Sublocations'},
    :status       => {name: :legal_status, type: :string, label: 'Legal Status'},
    :status_yr    => {name: :legal_status_updated_at, type: :year, label: 'Status Year'},
    :iucn_cat     => {name: :iucn_category, type: :string, label: 'IUCN Category'},
    :gov_type     => {name: :governance, type: :string, label: 'Governance'},
    :mang_auth    => {name: :management_authority, type: :string, label: 'Management Authority'},
    :mang_plan    => {name: :management_plan, type: :string, label: 'Management Plan'},
    :int_crit     => {name: :international_criteria, type: :string, label: 'International Criteria'},
    :no_take      => {name: :no_take_status, type: :string, label: 'No-take Status'},
    :no_tk_area   => {name: :no_take_area, type: :float, label: 'No-take Area'},
    :desig_eng    => {name: :designation, type: :string, label: 'Designation'},
    :desig_type   => {name: :jurisdiction, type: :string, label: 'Jurisdiction'},
    :wkb_geometry => {name: :the_geom, type: :geometry, label: 'Geometry'},
    :metadataid   => {name: :sources, type: :integer, label: 'Source'},
    :own_type     => {name: :owner_type, type: :string, label: 'Owner Type'},
    :pa_def       => {name: :is_oecm, type: :oecm, label: 'PA Def'}, # 0 means is_oecm is true
    :supp_info    => {name: :supplementary_info, type: :string, label: 'Supplementary Info'},
    :cons_obj     => {name: :conservation_objectives, type: :string, label: 'Conservation objectives'},
    :marine       => {name: :marine_type, type: :integer, label: 'Marine Type'},
    :verif        => {name: :verif, type: :string, label: 'Verified by' },
    :parent_iso3   => {name: :parent_iso3, type: :string, label: 'Parent ISO' }
  }

  POLYGON_ATTRIBUTES = [
    :gis_m_area,
    :gis_area,
    :shape_area,
    :shape_length
  ]

  module Matchers
    GEOMETRY_TABLE = /wdpa_?(wdoecm_)?po/i
    POLYGON_TABLE  = /poly/i
    SOURCE_TABLE   = /wdpa_?(wdoecm_)?source/i
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
    elsif !!(table =~ Matchers::SOURCE_TABLE)
      "standard_sources"
    else
      "standard_points"
    end
  end

  private


  def self.standardise_values hash
    standardised_attributes = {}

    hash.each do |key, value|
      attributes = Array.wrap(self::STANDARD_ATTRIBUTES[key])
      attributes.each do |attribute|
        standardised_value = Wdpa::Shared::TypeConverter.convert value, as: attribute[:type]
        standardised_attributes[attribute[:name]] = standardised_value
      end

      # Previously PP imported the :marine attribute from the WDPA release
      # as a boolean into the :marine field. We need the additional data
      # stored in the WDPA marine field, so we need to import the original data
      # and then generate the attribute for the existing boolean :marine field.
      if standardised_attributes[:marine_type]
        standardised_attributes[:marine] = marine_type_to_boolean(standardised_attributes[:marine_type])
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

  def self.marine_type_to_boolean(marine_type)
    marine_type.to_i == 0 ? false : true
  end
end
