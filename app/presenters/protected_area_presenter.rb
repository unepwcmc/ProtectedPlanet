class ProtectedAreaPresenter
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::UrlHelper

  POLYGON = -> (pa, _property) {
    type = ProtectedArea.select("ST_GeometryType(the_geom) AS type").where(id: pa.id).first.type
    type == "ST_MultiPolygon"
  }

  # Warning: do NOT use .present? there, as some of the possible values
  # are false. .present? will return false even if the value is not nil
  PRESENCE = -> (pa, property) { !pa.try(property).nil? }
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

  def affiliations
    [
      green_list_status_info,
      parcc_info
    ].compact
  end

  def data_info
    SECTIONS.each_with_object({}) do |section, all_info|
      all_info[section[:name]] = completeness_for(section[:fields])
    end
  end

  def external_links
    [
      dopa_link,
      world_heritage_outlook_link,
      story_map_links
    ].compact.flatten
  end

  def percentage_complete
    ((num_fields_with_data.to_f / all_fields.count) * 100).round(2)
  end

  def name_size
    {
      name: protected_area.name,
      wdpa_id: protected_area.wdpa_id,
      km: protected_area.gis_marine_area.to_i
    }
  end


  def marine_designation
    size = protected_area.reported_area.to_f.round(2)
    {
      name: protected_area.name,
      wdpa_id: protected_area.wdpa_id,
      country: marine_designation_country,
      iso: protected_area.countries.first.try(:iso_3),
      size: "#{number_with_delimiter(size, delimiter: ',')}km²",
      date: protected_area.legal_status_updated_at.year
    }
  end

  def attributes
    [
      {
        title: 'Original Name',
        value: protected_area.original_name
      },
      {
        title: 'English Designation',
        value: protected_area.designation.try(:name) || "Not Reported"
      },
      {
        title: 'IUCN Management Category',
        value: protected_area.iucn_category.try(:name) || "Not Reported"
      },
      {
        title: 'Status',
        value: protected_area.legal_status.try(:name) || "Not Reported"
      },
      {
        title: 'Type of Designation',
        value: protected_area.designation.try(:jurisdiction).try(:name) || "Not Reported"
      },
      {
        title: 'Status Year',
        value: protected_area.legal_status_updated_at.try(:strftime, '%Y') || "Not Reported"
      },
      {
        title: 'Sublocation',
        value: protected_area.sub_locations.map(&:iso).join(', ')
      },
      {
        title: 'Governance Type',
        value: protected_area.governance.try(:name) || "Not Reported"
      },
      {
        title: 'Management Authority',
        value: protected_area.management_authority.try(:name) || "Not Reported"
      },
      {
        title: 'Management Plan',
        value: parse_management_plan(protected_area.management_plan)
      },
      {
        title: 'International Criteria',
        value: protected_area.international_criteria || "Not Reported"
      }
    ].concat(oecm_attributes)
  end
  
  private

  def oecm_attributes
    return [] unless protected_area.is_oecm
    [
      {
        title: 'Supplementary Information',
        value: protected_area.supplementary_info
      },
      {
        title: 'Conservation Objectives',
        value: protected_area.conservation_objectives
      }
    ]
  end

  def green_list_status_info
    return unless protected_area.green_list_status_id

    gls = protected_area.green_list_status
    {
      affiliation: 'greenlist',
      date: gls.expiry_date,
      image_url: green_list_logo(gls.status),
      link_title: "View the Green List page for #{protected_area.name}",
      type: gls.status,
      url: protected_area.green_list_url
    }
  end

  def green_list_logo(status)
    logo = status.downcase == 'candidate' ? 'green-list-black' : 'green-list'
    ActionController::Base.helpers.image_url("logos/#{logo}.png")
  end

  def parcc_info
    return unless protected_area.has_parcc_info

    {
      image_url: ActionController::Base.helpers.image_url('logos/parcc.png'),
      link_title: "View the climate change vulnerability assessments for #{protected_area.name}",
      link_url: url_for_related_source('parcc_info', protected_area)
    }
  end

  def protected_area
    @protected_area
  end

  def marine_designation_country
    protected_area.countries.first.try(:name) || "Area Beyond National Jurisdiction"
  end

  def completeness_for attributes
    attributes.map do |attribute|
      standard_attr = standard_attributes[attribute[:field]]

      {
        label: standard_attr[:label],
        complete: attribute[:assert].call(
          protected_area, standard_attr[:name]
        )
      }
    end
  end

  def dopa_link 
    return unless protected_area.is_dopa
    {
      link: url_for_related_source('dopa_info', protected_area),
      text: I18n.t('stats.dopa.title'),
      button_title: I18n.t('stats.dopa.button-title', name: protected_area.name) #TODO Not used?
    }
  end

  def world_heritage_outlook_link
    return unless protected_area.is_whs?
    {
      link: url_for_related_source('who_info', protected_area),
      text: I18n.t('stats.who.title'),
      button_title: I18n.t('stats.who.button-title', name: protected_area.name) #TODO Not used?
    }
  end

  def num_fields_with_data
    all_fields.count do |attribute|
      standard_attr = standard_attributes[attribute[:field]]

      attribute[:assert].call(
        protected_area, standard_attr[:name]
      )
    end
  end

  def parse_management_plan management_plan
    if (management_plan.is_a? String) && (management_plan.starts_with?("http"))
      ActionController::Base.helpers.link_to("View Management Plan", management_plan)
    else
      management_plan
    end
  end

  def url_for_related_source source, protected_area
    File.join(
      Rails.application.secrets.related_sources_base_urls[source.to_sym],
      protected_area.wdpa_id.to_s
    )
  end

  def all_fields
    SECTIONS.flat_map { |section| section[:fields] }
  end

  def standard_attributes
    Wdpa::DataStandard::STANDARD_ATTRIBUTES
  end

  def story_map_links
    @protected_area.story_map_links.map { |link|
      {
        title: I18n.t('stats.story_map.title'),
        text: I18n.t('stats.story_map.link_type.' + link.link_type.gsub(/\s/, '_').parameterize),
        link: link.link
      }
    }
  end
end
