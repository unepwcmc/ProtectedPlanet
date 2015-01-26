class ProtectedAreaPresenter
  def initialize protected_area
    @protected_area = protected_area
  end

  def data_info
    sections.each_with_object({}) do |section, all_info|
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

  def sections
    @sections ||= [{
      name: 'Basic Info',
      fields: [:wdpaid, :wdpa_pid, :metadataid, :name, :orig_name, :marine]
    }, {
      name: 'Geometries',
      fields: [:gis_m_area, :gis_area, :wkb_geometry]
    }, {
      name: 'Categorisation',
      fields: [:iso3, :sub_loc, :iucn_cat, :gov_type, :mang_auth, :mang_plan, :int_crit, :desig_eng, :desig_type]
    }, {
      name: 'Special',
      fields: [:no_take, :no_tk_area]
    }]
  end

  def completeness_for attributes
    attributes.map do |attribute|
      standard_attr = standard_attributes[attribute]

      {
        label: standard_attr[:label],
        complete: !protected_area.try(standard_attr[:name]).nil?
      }
    end
  end

  # Warning: do NOT use .present? there, as some of the possible values
  # are false. .present? will return false even if the value is not nil
  def num_fields_with_data
    standard_attributes.values.count do |attribute|
      !protected_area.try(attribute[:name]).nil?
    end
  end

  def standard_attributes
    Wdpa::DataStandard::STANDARD_ATTRIBUTES
  end
end
