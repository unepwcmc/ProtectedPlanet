module Download
  module Queries
    POINTS_COLUMNS = %i[
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

    POLYGONS_COLUMNS = POINTS_COLUMNS.clone
      .insert(13, :gis_m_area).insert(15, :gis_area)

    SOURCE_COLUMNS = %i[
      metadataid data_title resp_party
      year update_yr char_set
      ref_system scale lineage
      citation disclaimer language
      verifier
    ]

    def self.for_points(extra_columns = {})
      aliased_columns = POINTS_COLUMNS.map do |column|
        %(#{column} AS "#{column.upcase}")
      end

      extra_columns.each do |(position, name)|
        aliased_columns.insert(position, name)
      end

      points_view = Wdpa::Portal::Config::PortalImportConfig::PORTAL_MATERIALISED_VIEWS['points']
      { select: "#{aliased_columns.join(',')}", from: points_view }
    end

    def self.for_polygons
      aliased_columns = POLYGONS_COLUMNS.map do |column|
        %(#{column} AS "#{column.upcase}")
      end.join(',')

      polygons_view = Wdpa::Portal::Config::PortalImportConfig::PORTAL_MATERIALISED_VIEWS['polygons']
      { select: "#{aliased_columns}", from: polygons_view }
    end

    def self.build_query_for_downloads_view(with_type)
      add_type = ->(type) { %('#{type}' AS "TYPE", ) if with_type }
      points = for_points({ 13 => %(NULL AS "GIS_M_AREA"), 15 => %(NULL AS "GIS_AREA") })

      selected_columns = with_type ? '*' : for_polygons[:select]
      from = "
        (SELECT #{add_type['Polygon']} #{for_polygons[:select]}
        FROM #{for_polygons[:from]}
        UNION ALL
        SELECT #{add_type['Point']} #{points[:select]}
        FROM #{points[:from]}) AS all_pas
      ".squish

      { select: selected_columns, from: from }
    end
  end
end
