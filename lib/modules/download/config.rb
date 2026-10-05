module Download
  module Config
    PORTAL_POINTS_COLUMNS = %i[
      wkb_geometry
      site_id site_pid
      site_type name_eng name
      desig desig_eng desig_type
      iucn_cat int_crit
      realm
      rep_m_area rep_area
      no_take no_tk_area
      status status_yr
      gov_type govsubtype
      own_type ownsubtype
      mang_auth mang_plan
      verif metadataid
      prnt_iso3 iso3
      supp_info cons_obj
      inlnd_wtrs
      oecm_asmt
    ]

    PORTAL_POLYGONS_COLUMNS = PORTAL_POINTS_COLUMNS.clone
      .insert(13, :gis_m_area).insert(15, :gis_area)

    PORTAL_SOURCE_COLUMNS = %i[
      metadataid data_title resp_party
      year update_yr char_set
      ref_system scale lineage
      citation disclaimer language
      verifier
    ]

    # View names
    def self.points_view
      Wdpa::Portal::Config::PortalImportConfig.portal_materialised_views_hash[:points][:live]
    end

    def self.polygons_view
      Wdpa::Portal::Config::PortalImportConfig.portal_materialised_views_hash[:polygons][:live]
    end

    def self.sources_view
      Wdpa::Portal::Config::PortalImportConfig.portal_materialised_views_hash[:sources][:live]
    end

    def self.downloads_view
      Wdpa::Portal::Config::PortalImportConfig::PORTAL_DOWNALOAD_VIEWS
    end

    # Column names – centralised in a single hash for easy maintenance
    def self.download_view_column_names
      {
        site_id:  'SITE_ID',
        site_pid: 'SITE_PID',
        iso3:     'ISO3',
        site_type: 'SITE_TYPE',
        realm:    'REALM',
        iucn_cat: 'IUCN_CAT',
        desig_eng: 'DESIG_ENG',
        gov_type: 'GOV_TYPE'
      }
    end

    def self.pa_site_type_value
      'PA'
    end

    def self.oecm_site_type_value
      'OECM'
    end

    def self.terrestrial_realm_values
      ['Terrestrial']
    end

    def self.marine_realm_values
      ['Marine', 'Coastal']
    end

    # Labels for filenames
    def self.current_label
      Release.current_label
    end

    # Column definitions
    def self.points_columns
      PORTAL_POINTS_COLUMNS
    end

    def self.polygons_columns
      PORTAL_POLYGONS_COLUMNS
    end

    def self.source_columns
      PORTAL_SOURCE_COLUMNS
    end
  end
end