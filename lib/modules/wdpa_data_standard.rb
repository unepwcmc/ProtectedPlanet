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
    :status_yr  => {name: :legal_status_updated_at, type: :year},
    :iucn_cat   => {name: :iucn_category, type: :string},
    :gov_type   => {name: :governance, type: :string},
    :mang_auth  => {name: :management_authority, type: :string},
    :int_crit   => {name: :international_criteria, type: :string},
    :no_take    => {name: :no_take, type: :string},
    :no_tk_area => {name: :no_take_area, type: :float}
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

      if key == :iucn_category
        attributes[:iucn_category] = IucnCategory.where(name: attributes[:iucn_category]).first
      end

      if key == :governance
        attributes[:governance] = Governance.where(name: attributes[:governance]).first
      end

      if key == :management_authority
        attributes[:management_authority] = ManagementAuthority.where(name: attributes[:management_authority]).first
      end
    end
  end
end
