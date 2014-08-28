class @ProtectedAreaMap
  constructor: ($container) ->
    @map = L.map($container.attr('id'), {zoomControl: false, scrollWheelZoom: false})

    L.tileLayer('http://api.tiles.mapbox.com/v3/unepwcmc.ijh17499/{z}/{x}/{y}.png').addTo(@map)

  _generateCartocssSelector: (args) ->
    tables = args.table
    tables = [tables] unless $.isArray(tables)

    if args.attrName and args.attrVal
      comparator = "[#{args.attrName} = #{args.attrVal}]"
      mapFunction = (value) -> "##{value}#{comparator}"
    else
      mapFunction = (value) -> "##{value}"

    return tables.map(mapFunction).join(',')

  _generateCartocss: (args) ->
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

  addCountryTiles: (tileConfig, sublayers) ->
    args =
      table: 'countries_geometries'
      attrName: 'iso_3'
      attrVal: "'#{tileConfig.iso3}'"
      opacity: .2
      lineWidth: 0

    sublayers.push
      sql: "SELECT * FROM #{args.table} WHERE iso_3 = '#{tileConfig.iso3}'"
      cartocss: @_generateCartocss(args)
    sublayers

  addRegionTiles: (tileConfig, sublayers) ->
    args =
      table: 'continents'
      attrName: 'continent'
      attrVal: "'#{tileConfig.regionName}'"
      opacity: .2
      lineWidth: 0

    sublayers.push
      sql: "SELECT * FROM #{args.table} WHERE continent = '#{tileConfig.regionName}'"
      cartocss: @_generateCartocss(args)
    sublayers

  addWdpaTiles: (tileConfig, sublayers) ->
    cartocss = [
      @_generateCartocss(
        table: ['wdpa_poly', 'wdpa_point']
        lineColor: '40541b'
        polygonFill: '83ad35'
      )
    ]

    if tileConfig.wdpaId?
      cartocss.push @_generateCartocss(
        table: ['wdpa_poly', 'wdpa_point']
        attrName: 'wdpaid'
        attrVal: tileConfig.wdpaId
      )

    sublayers.push
      sql: "SELECT the_geom FROM wdpa_point UNION ALL SELECT the_geom FROM wdpa_poly"
      cartocss: cartocss.join("\n")
    sublayers

  addCartodbTiles: (tileConfig) ->
    sublayers = []

    @addWdpaTiles(tileConfig, sublayers)

    if tileConfig.iso3?
      sublayers = @addCountryTiles tileConfig, sublayers
    if tileConfig.regionName?
      sublayers = @addRegionTiles tileConfig, sublayers

    carto_tiles = new cartodb.Tiles(
      sublayers: sublayers
      user_name: "carbon-tool"
    )

    carto_tiles.getTiles( (o) =>
      L.tileLayer(o.tiles[0]).addTo @map
    )

  _calculateBoundWidth: (bounds) ->
    x1 = bounds[0][1]
    x2 = bounds[1][1]
    if x1 < 0 and x2 >= 0
      return Math.abs(x1) + Math.abs(x2)
    else
      max = Math.max(Math.abs(x1), Math.abs(x2))
      min = Math.min(Math.abs(x1), Math.abs(x2))
      return max - min

  normalizeBounds: (bounds) ->
    # If a protected area overlaps the antimeridian ST_Extent does not
    # return a correct bounding box (Ideas to fix this?)
    # So, assuming that no protected areas real bbox width is bigger than 300,
    # if this is the case correct to a fixed 10 degree width. 
    if @_calculateBoundWidth(bounds) > 300
      bounds[1][1] = -170
    bounds

  fitToBounds: (bounds, withPadding) ->
    opts = {}
    if withPadding?
      padding = @calculatePadding()
      opts.paddingTopLeft = padding.topLeft
      opts.paddingBottomRight = padding.bottomRight

    @map.fitBounds(@normalizeBounds(bounds), opts)

  setZoomControl: (position) ->
    @map.addControl(L.control.zoom(position: position))

  locate: ->
    @map.locate(setView: true)

  calculatePadding: ->
    mapSize = @map.getSize()
    paddingLeft = mapSize.x/5
    {topLeft: [paddingLeft, 50], bottomRight: [0,70]}
