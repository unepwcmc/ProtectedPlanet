class @ProtectedAreaMap
  constructor: ($container) ->
    @map = L.map($container.attr('id'), {zoomControl: false, scrollWheelZoom: false})

    L.tileLayer('http://api.tiles.mapbox.com/v3/unepwcmc.ijh17499/{z}/{x}/{y}.png').addTo(@map)

  
  _addSelectedStyle: (args) ->
    opacity = if args.opacity? then args.opacity else .5
    lineWidth = if args.lineWidth? then args.lineWidth else 1
    args.cartocss += """
      ##{args.table}[#{args.attrName} = #{args.attrVal}]{
        line-color:#D41623;
        line-width:#{lineWidth};
        polygon-fill:#E43430;
        polygon-opacity:#{opacity};}
    """

  addSelectedWdpaTiles: (tileConfig, sublayers, idx) ->
    args = 
      cartocss: sublayers[idx].cartocss
      table: 'wdpapoly_july2014_0'
      attrName: 'wdpaid'
      attrVal: tileConfig.wdpaId
    cartocss = @_addSelectedStyle args

    sublayers[idx].cartocss = cartocss
    sublayers

  addCountryTiles: (tileConfig, sublayers) ->
    args = 
      cartocss: ''
      table: 'countries_geometries'
      attrName: 'iso_3'
      attrVal: "'#{tileConfig.iso3}'"
      opacity: .2
      lineWidth: 0

    sublayers.push 
      sql: "select * from #{args.table} where iso_3 = '#{tileConfig.iso3}'"
      cartocss: @_addSelectedStyle args
    sublayers

  addRegionTiles: (tileConfig, sublayers) ->
    args = 
      cartocss: ''
      table: 'continents'
      attrName: 'continent'
      attrVal: "'#{tileConfig.regionName}'"
      opacity: .2
      lineWidth: 0

    sublayers.push 
      sql: "select * from #{args.table} where continent = '#{tileConfig.regionName}'"
      cartocss: @_addSelectedStyle args
    sublayers

  addCartodbTiles: (tileConfig) ->
    # Always show the wdpa layer:
    cartocss = """
      #wdpapoly_july2014_0{
        line-color:#40541b;
        line-width:0.4;
        polygon-fill:#83ad35;
        polygon-opacity:0.4;}
    """
    sublayers = [
      sql: "select * from wdpapoly_july2014_0"
      cartocss: cartocss
    ]
    if tileConfig.wdpaId?
      sublayers = @addSelectedWdpaTiles tileConfig, sublayers, 0
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

  normalizeBounds: (bounds) ->
    # If a protected area overlaps the antimeridian ST_Extent does not 
    # return a correct bounding box (Ideas to fix this?)
    # So, assuming that no protected areas real bbox width is bigger than 300,
    # if this is the case correct to a fixed 10 degree width.
    if Math.abs(bounds[0][1]) + Math.abs(bounds[1][1]) > 300
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
    {topLeft: [paddingLeft, 50], bottomRight: [0, 50]}
