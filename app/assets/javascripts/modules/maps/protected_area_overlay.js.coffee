define('protected_area_overlay', [], () ->
  class ProtectedAreaOverlay
    POLYGONS_TABLE = 'wdpa_poly_production'
    POINTS_TABLE   = 'wdpa_point_production'

    @_generateCartocssSelector: (args) ->
      tables = args.table
      tables = [tables] unless $.isArray(tables)

      if args.attrName and args.attrVal
        value = if typeof args.attrVal is "number" then args.attrVal else "\"#{args.attrVal}\""
        comparator = "[#{args.attrName} = #{value}]"
        mapFunction = (value) -> "##{value}#{comparator}"
      else
        mapFunction = (value) -> "##{value}"

      return tables.map(mapFunction).join(',')

    @_generateCartocss: (args) ->
      args = $.extend({
        opacity: 0.7
        lineWidth: 0.05
        lineColor: '2B3146'
        polygonFill: '2B3146',
        polygonCompOp: 'dst-over'
      }, args)

      """
        #{@_generateCartocssSelector(args)} {
          line-color:##{args.lineColor};
          line-width:#{args.lineWidth};
          polygon-fill:##{args.polygonFill};
          polygon-opacity:#{args.opacity};
          polygon-comp-op:#{args.polygonCompOp};
        }
      """

    @_countryTiles: (iso3) ->
      args =
        table: 'countries_geometries'
        attrName: 'iso_3'
        attrVal: "'#{iso3}'"
        opacity: .2
        lineWidth: 0

      {
        sql: "SELECT * FROM #{args.table} WHERE iso_3 = '#{iso3}'"
        cartocss: @_generateCartocss(args)
      }

    @_regionTiles: (regionName) ->
      args =
        table: 'continents'
        attrName: 'continent'
        attrVal: "'#{regionName}'"
        opacity: .2
        lineWidth: 0

      {
        sql: "SELECT * FROM #{args.table} WHERE continent = '#{regionName}'"
        cartocss: @_generateCartocss(args)
      }

    @_wdpa_where_clause: (config) ->
      clauses = []

      if config.iucnCategory?
        clauses.push "iucn_cat IN (#{config.iucnCategory.map((c) -> "'#{c}'").join(',')})"

      if config.marine?
        clauses.push "marine = '#{config.marine}'"

      if clauses.length > 0
        "WHERE #{clauses.join(" AND ")}"
      else
        ""

    @_wdpaTiles: (config) ->
      cartocss = [
        @_generateCartocss(
          table: [POLYGONS_TABLE, POINTS_TABLE]
          lineColor: '40541b'
          polygonFill: '229A00'
          opacity: .1
          lineWidth: .1
        ),

        @_generateCartocss(
          table: [POLYGONS_TABLE, POINTS_TABLE]
          lineColor: '2E5387'
          polygonFill: '3E7BB6'
          attrName: 'marine'
          attrVal: '1'
          opacity: .1
        )
      ]

      if config.wdpaId?
        cartocss.push @_generateCartocss(
          table: [POLYGONS_TABLE, POINTS_TABLE]
          attrName: 'wdpaid'
          attrVal: config.wdpaId,
          lineColor: 'FF6600',
          lineWidth: 2,
          opacity: 0.2,
          polygonCompOp: 'src-over'
        )

      {
        sql: "SELECT the_geom, the_geom_webmercator, wdpaid, marine FROM #{POINTS_TABLE} #{@_wdpa_where_clause(config)} UNION ALL SELECT the_geom, the_geom_webmercator, wdpaid, marine FROM #{POLYGONS_TABLE} #{@_wdpa_where_clause(config)}"
        cartocss: cartocss.join("\n")
      }

    @render: (map, config) ->
      sublayers = []
      sublayers.push @_wdpaTiles(config)
      sublayers.push @_countryTiles(config.iso3) if config.iso3?
      sublayers.push @_regionTiles(config.regionName) if config.regionName?

      carto_tiles = new cartodb.Tiles(
        sublayers: sublayers
        user_name: "carbon-tool"
      )

      map.on('baselayerchange', => @paOverlay.bringToFront())
      carto_tiles.getTiles( (o) => @paOverlay = L.tileLayer(o.tiles[0]).addTo(map))

  return ProtectedAreaOverlay
)
