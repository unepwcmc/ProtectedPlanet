window.ProtectedPlanet ||= {}
window.ProtectedPlanet.Maps ||= {}

class ProtectedPlanet.Maps.ProtectedAreaOverlay
  #POLYGONS_TABLE = 'wdpa_poly_<%= Rails.env %>'
  #POINTS_TABLE   = 'wdpa_point_<%= Rails.env %>'
  POLYGONS_TABLE = 'wdpa_poly_production'
  POINTS_TABLE   = 'wdpa_point_production'

  @_generateCartocssSelector: (args) ->
    tables = args.table
    tables = [tables] unless $.isArray(tables)

    if args.attrName and args.attrVal
      comparator = "[#{args.attrName} = #{args.attrVal}]"
      mapFunction = (value) -> "##{value}#{comparator}"
    else
      mapFunction = (value) -> "##{value}"

    return tables.map(mapFunction).join(',')

  @_generateCartocss: (args) ->
    args = $.extend({
      opacity: 0.7
      lineWidth: 0.05
      lineColor: 'D41623'
      polygonFill: 'E43430'
    }, args)

    """
      #{@_generateCartocssSelector(args)} {
        line-color:##{args.lineColor};
        line-width:#{args.lineWidth};
        polygon-fill:##{args.polygonFill};
        polygon-opacity:#{args.opacity};
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

  @_wdpaTiles: (wdpaId) ->
    cartocss = [
      @_generateCartocss(
        table: [POLYGONS_TABLE, POINTS_TABLE]
        lineColor: '40541b'
        polygonFill: '83ad35'
      )
    ]

    if wdpaId?
      cartocss.push @_generateCartocss(
        table: [POLYGONS_TABLE, POINTS_TABLE]
        attrName: 'wdpaid'
        attrVal: wdpaId
      )

    {
      sql: "SELECT the_geom, the_geom_webmercator, wdpaid FROM #{POINTS_TABLE} UNION ALL SELECT the_geom, the_geom_webmercator, wdpaid FROM #{POLYGONS_TABLE}"
      cartocss: cartocss.join("\n")
    }

  @render: (map, config) ->
    sublayers = []
    sublayers.push @_wdpaTiles(config.wdpaId)
    sublayers.push @_countryTiles(config.iso3) if config.iso3?
    sublayers.push @_regionTiles(config.regionName) if config.regionName?

    carto_tiles = new cartodb.Tiles(
      sublayers: sublayers
      user_name: "carbon-tool"
    )

    map.on('baselayerchange', => @paOverlay.bringToFront())
    carto_tiles.getTiles( (o) => @paOverlay = L.tileLayer(o.tiles[0]).addTo(map))
