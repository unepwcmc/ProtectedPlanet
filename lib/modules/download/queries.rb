module Download
  module Queries
    def self.build_query_for_downloads_view
      add_type = ->(type) { %('#{type}' AS "TYPE", ) }
      points = for_points({ 13 => %(NULL AS "GIS_M_AREA"), 15 => %(NULL AS "GIS_AREA") })

      from = "
        (SELECT #{add_type['Polygon']} #{for_polygons[:select]}
        FROM #{for_polygons[:from]}
        UNION ALL
        SELECT #{add_type['Point']} #{points[:select]}
        FROM #{points[:from]}) AS all_pas
      ".squish

      { select: '*', from: from }
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

    private_class_method :for_points, :for_polygons
  end
end
