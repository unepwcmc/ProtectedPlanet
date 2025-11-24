module Download
  module Queries
    def self.build_query_for_downloads_view(type)
      case type
      when 'portal'
        build_portal_query_for_downloads_view
      when 'legacy'
        build_legacy_query_for_downloads_view
      else
        raise ArgumentError, "Invalid type '#{type}'. Must be 'portal' or 'legacy'"
      end
    end

    def self.for_points(extra_columns = {})
      aliased_columns = Download::Config.points_columns.map do |column|
        %(#{column} AS "#{column.upcase}")
      end

      extra_columns.each do |(position, name)|
        aliased_columns.insert(position, name)
      end

      { select: "#{aliased_columns.join(',')}", from: Download::Config.points_view }
    end

    def self.for_polygons
      aliased_columns = Download::Config.polygons_columns.map do |column|
        %(#{column} AS "#{column.upcase}")
      end.join(',')

      { select: "#{aliased_columns}", from: Download::Config.polygons_view }
    end

    def self.build_portal_query_for_downloads_view
      add_type = ->(type) { %('#{type}' AS "TYPE", ) }
      points = for_points({ 13 => %(NULL AS "GIS_M_AREA"), 15 => %(NULL AS "GIS_AREA") })

      selected_columns = '*'
      from = "
        (SELECT #{add_type['Polygon']} #{for_polygons[:select]}
        FROM #{for_polygons[:from]}
        UNION ALL
        SELECT #{add_type['Point']} #{points[:select]}
        FROM #{points[:from]}) AS all_pas
      ".squish

      { select: selected_columns, from: from }
    end

    def self.build_legacy_query_for_downloads_view
      add_type = ->(type) { %{'#{type}' AS "TYPE", } }
      points = for_points({ 13 => %{NULL AS "GIS_M_AREA"}, 15 => %{NULL AS "GIS_AREA"} })

      selected_columns = '*'
      from = "
        (SELECT #{add_type['Polygon']} #{for_polygons[:select]}
        FROM #{for_polygons[:from]}
        UNION ALL
        SELECT #{add_type['Point']} #{points[:select]}
        FROM #{points[:from]}) AS all_pas
      ".squish

      { select: selected_columns, from: from }
    end

    private_class_method :for_points, :for_polygons, :build_portal_query_for_downloads_view, :build_legacy_query_for_downloads_view
  end
end
