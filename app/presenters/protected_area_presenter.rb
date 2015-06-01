class ProtectedAreaPresenter
  POLYGON = -> (geom) { geom.try(:geometry_type) == RGeo::Feature::MultiPolygon }

  # Warning: do NOT use .present? there, as some of the possible values
  # are false. .present? will return false even if the value is not nil
  PRESENCE = -> (obj) { !obj.nil? }
  ASSERT_PRESENCE = lambda { |field| {field: field, assert: PRESENCE} }

  SECTIONS = [{
      name: 'Basic Info',
      fields: [:wdpaid, :wdpa_pid, :metadataid, :name, :orig_name, :marine].map(&ASSERT_PRESENCE)
    }, {
      name: 'Geometries',
      fields: [:gis_m_area, :gis_area].map(&ASSERT_PRESENCE) | [{field: :wkb_geometry, assert: POLYGON}]
    }, {
      name: 'Categorisation',
      fields: [:iso3, :sub_loc, :iucn_cat, :gov_type, :mang_auth, :mang_plan, :int_crit, :desig_eng, :desig_type].map(&ASSERT_PRESENCE)
    }, {
      name: 'Special',
      fields: [:no_take, :no_tk_area].map(&ASSERT_PRESENCE)
    }
  ]

  def initialize protected_area
    @protected_area = protected_area
  end

  def data_info
    SECTIONS.each_with_object({}) do |section, all_info|
      all_info[section[:name]] = completeness_for(section[:fields])
    end
  end

  def percentage_complete
    ((num_fields_with_data.to_f / standard_attributes.count) * 100).round(2)
  end

  private

  def protected_area
    @protected_area
  end


  def completeness_for attributes
    attributes.map do |attribute|
      standard_attr = standard_attributes[attribute[:field]]

      {
        label: standard_attr[:label],
        complete: attribute[:assert].call(
          protected_area.try(standard_attr[:name])
        )
      }
    end
  end

  def num_fields_with_data
    SECTIONS.flat_map { |section| section[:fields] }.count do |attribute|
      standard_attr = standard_attributes[attribute[:field]]

      attribute[:assert].call(
        protected_area.try(standard_attr[:name])
      )
    end
  end

  def standard_attributes
    Wdpa::DataStandard::STANDARD_ATTRIBUTES
  end
end
