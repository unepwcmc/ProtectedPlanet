# frozen_string_literal: true

class ProtectedAreaPresenter
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::UrlHelper

  POLYGON = lambda { |pa, _property|
    type = ProtectedArea.select('ST_GeometryType(the_geom) AS type').where(id: pa.id).first.type
    type == 'ST_MultiPolygon'
  }

  # Warning: do NOT use .present? there, as some of the possible values
  # are false. .present? will return false even if the value is not nil
  PRESENCE = ->(pa, property) { !pa.try(property).nil? }
  ASSERT_PRESENCE = ->(field) { { field: field, assert: PRESENCE } }

  def initialize(protected_area)
    @protected_area = protected_area
  end

  def affiliations
    [
      green_list_status_info,
      parcc_info
    ].compact
  end

  def external_links
    [
      dopa_link,
      world_heritage_outlook_link,
      story_map_links
    ].compact.flatten
  end

  def name_size
    {
      name: protected_area.name,
      site_id: protected_area.site_id,
      km: protected_area.gis_marine_area.to_i
    }
  end

  def marine_designation
    size = protected_area.reported_area.to_f.round(2)
    {
      name: protected_area.name,
      site_id: protected_area.site_id,
      country: marine_designation_country,
      iso: protected_area.countries.first.try(:iso_3),
      size: "#{number_with_delimiter(size, delimiter: ',')}km²",
      date: protected_area.legal_status_updated_at.year
    }
  end

  def parcels_attribute
    parcels_including_protected_area_self = protected_area.parcels_including_protected_area_self
    # TODO: once the parcel IDs are change to be 345345_1 345345_2
    # We will need to change this to item.split('_').last.to_i
    parcels_including_protected_area_self.sort_by { |item| item.site_pid }.map do |parcel|
      {
        site_pid: parcel.site_pid,
        attributes: [
          {
            title: 'Original Name',
            value: parcel.original_name
          },
          {
            title: 'English Designation',
            value: parcel.designation.try(:name) || 'Not Reported'
          },
          {
            title: 'IUCN Management Category',
            value: parcel.iucn_category.try(:name) || 'Not Reported'
          },
          {
            title: 'Status',
            value: parcel.legal_status.try(:name) || 'Not Reported'
          },
          {
            title: 'Type of Designation',
            value: parcel.designation.try(:jurisdiction).try(:name) || 'Not Reported'
          },
          {
            title: 'Status Year',
            value: parcel.legal_status_updated_at.try(:strftime, '%Y') || 'Not Reported'
          },
          {
            title: 'Governance Type',
            value: parcel.governance.try(:name) || 'Not Reported'
          },
          {
            title: 'Governance Subtype',
            value: parcel.governance_subtype || 'Not Reported'
          },
          {
            title: 'Management Authority',
            value: parcel.management_authority.try(:name) || 'Not Reported'
          },
          {
            title: 'Management Plan',
            value: parse_management_plan(parcel.management_plan)
          },
          {
            title: 'Ownership Type',
            value: parcel.owner_type || 'Not Reported'
          },
          {
            title: 'Ownership Subtype',
            value: parcel.ownership_subtype || 'Not Reported'
          },
          {
            title: 'International Criteria',
            value: parcel.international_criteria || 'Not Reported'
          }
        ].concat(parcel_oecm_attributes(parcel))
      }
    end
  end

  private

  def parcel_oecm_attributes(parcel)
    return [] unless parcel.is_oecm

    [
      {
        title: 'Supplementary Information',
        value: parcel.supplementary_info
      },
      {
        title: 'Conservation Objectives',
        value: parcel.conservation_objectives
      },
      {
        title: 'Inland Waters',
        value: parcel.inland_waters || 'Not Reported'
      },
      {
        title: 'OECM Assessment',
        value: parcel.oecm_assessment || 'Not Reported'
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

  attr_reader :protected_area

  def marine_designation_country
    protected_area.countries.first.try(:name) || 'Area Beyond National Jurisdiction'
  end

  # As of 07Apr2025 it doesn't seem to be used
  def completeness_for(attributes)
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
      button_title: I18n.t('stats.dopa.button-title', name: protected_area.name)
    }
  end

  def world_heritage_outlook_link
    return unless protected_area.is_whs?

    {
      link: url_for_related_source('who_info', protected_area),
      text: I18n.t('stats.who.title'),
      button_title: I18n.t('stats.who.button-title', name: protected_area.name)
    }
  end

  def parse_management_plan(management_plan)
    if (management_plan.is_a? String) && management_plan.starts_with?('http')
      ActionController::Base.helpers.link_to('View Management Plan', management_plan)
    else
      management_plan
    end
  end

  def url_for_related_source(source, protected_area)
    File.join(
      Rails.application.secrets.related_sources_base_urls[source.to_sym],
      protected_area.site_id.to_s
    )
  end

  # As of 07Apr2025 it doesn't seem to be used
  def standard_attributes
    Wdpa::DataStandard::STANDARD_ATTRIBUTES
  end

  def story_map_links
    @protected_area.story_map_links.map do |link|
      {
        title: I18n.t('stats.story_map.title'),
        text: I18n.t('stats.story_map.link_type.' + link.link_type.gsub(/\s/, '_').parameterize),
        link: link.link
      }
    end
  end
end
