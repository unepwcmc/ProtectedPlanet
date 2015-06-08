module Download
  module Queries
    POINTS_COLUMNS = [
      :wkb_geometry, :wdpaid, :wdpa_pid,
      :pa_def, :name, :orig_name,
      :desig, :desig_eng, :desig_type,
      :iucn_cat, :int_crit, :marine,
      :rep_m_area, :rep_area, :no_take,
      :no_tk_area, :status, :status_yr,
      :gov_type, :own_type, :mang_auth,
      :mang_plan, :verif, :metadataid,
      :sub_loc, :parent_iso3, :iso3
    ]

    POLYGONS_COLUMNS = POINTS_COLUMNS.clone
      .insert(13, :gis_m_area).insert(15, :gis_area)

    def self.for_points extra_columns={}
      aliased_columns = POINTS_COLUMNS.map { |column|
        %{#{column} AS "#{column.upcase}"}
      }

      extra_columns.each { |(position, name)|
        aliased_columns.insert(position, name)
      }

      {select: "#{aliased_columns.join(',')}", from: 'standard_points'}
    end

    def self.for_polygons
      aliased_columns = POLYGONS_COLUMNS.map { |column|
        %{#{column} AS "#{column.upcase}"}
      }.join(',')

      {select: "#{aliased_columns}", from: 'standard_polygons', where: ''}
    end

    def self.mixed
      points = for_points({13 => %{NULL AS "GIS_M_AREA"}, 15 => %{NULL AS "GIS_AREA"}})
      """
        SELECT 'Polygon' as \"TYPE\", #{for_polygons[:select]}
        FROM #{for_polygons[:from]}
        UNION ALL
        SELECT 'Point' as \"TYPE\", #{points[:select]}
        FROM #{points[:from]}
      """.squish
    end
  end
end
