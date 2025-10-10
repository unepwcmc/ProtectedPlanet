module Download
  module Config
    # Standard columns for when there's no portal release
    STANDARD_POINTS_COLUMNS = %i[
      wkb_geometry wdpaid wdpa_pid
      pa_def name orig_name
      desig desig_eng desig_type
      iucn_cat int_crit marine
      rep_m_area rep_area no_take
      no_tk_area status status_yr
      gov_type own_type mang_auth
      mang_plan verif metadataid
      sub_loc parent_iso3 iso3
      supp_info cons_obj
    ]

    STANDARD_POLYGONS_COLUMNS = STANDARD_POINTS_COLUMNS.clone
      .insert(13, :gis_m_area).insert(15, :gis_area)

    STANDARD_SOURCE_COLUMNS = %i[
      metadataid data_title resp_party
      year update_yr char_set
      ref_system scale lineage
      citation disclaimer language
      verifier
    ]

    # Portal columns for when there's a portal release
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

    # Check if there's a current release (portal release)
    def self.has_successful_portal_release?
      Release.current_release.present?
    end

    # View names
    def self.points_view
      has_successful_portal_release? ? 
        Wdpa::Portal::Config::PortalImportConfig::PORTAL_MATERIALISED_VIEWS['points'] : 
        'standard_points'
    end

    def self.polygons_view
      has_successful_portal_release? ? 
        Wdpa::Portal::Config::PortalImportConfig::PORTAL_MATERIALISED_VIEWS['polygons'] : 
        'standard_polygons'
    end

    def self.sources_view
      has_successful_portal_release? ? 
        Wdpa::Portal::Config::PortalImportConfig::PORTAL_MATERIALISED_VIEWS['sources'] : 
        'standard_sources'
    end

    def self.downloads_view
      has_successful_portal_release? ? 
        Wdpa::Portal::Config::PortalImportConfig::PORTAL_VIEWS['downloads'] : 
        Wdpa::Release::DOWNLOADS_VIEW_NAME
    end

    # Column names
    def self.id_column
      has_successful_portal_release? ? "SITE_ID" : "WDPAID"
    end

    # Labels for filenames
    def self.current_label
      has_successful_portal_release? ? 
        Release.current_label : 
        Wdpa::S3.current_wdpa_identifier
    end

    # Column definitions
    def self.points_columns
      has_successful_portal_release? ? 
        PORTAL_POINTS_COLUMNS : 
        STANDARD_POINTS_COLUMNS
    end

    def self.polygons_columns
      has_successful_portal_release? ? 
        PORTAL_POLYGONS_COLUMNS : 
        STANDARD_POLYGONS_COLUMNS
    end

    def self.source_columns
      has_successful_portal_release? ? 
        PORTAL_SOURCE_COLUMNS : 
        STANDARD_SOURCE_COLUMNS
    end
  end
end