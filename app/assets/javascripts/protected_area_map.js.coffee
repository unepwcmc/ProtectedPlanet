class @ProtectedAreaMap
  constructor: ($container) ->
    @map = L.map($container.attr('id'), {zoomControl: false, scrollWheelZoom: false})

    L.tileLayer('http://api.tiles.mapbox.com/v3/unepwcmc.ijh17499/{z}/{x}/{y}.png').addTo(@map)

  addWdpaTiles: (wdpaId) ->
    cartocss = """
      #wdpapoly_july2014_0{
        line-color:#40541b;
        line-width:0.4;
        polygon-fill:#83ad35;
        polygon-opacity:0.4;}
    """

    if wdpaId?
      cartocss += """
        #wdpapoly_july2014_0[wdpaid = #{wdpaId}]{
          line-color:#D41623;
          line-width:1;
          polygon-fill:#E43430;
          polygon-opacity:0.5;}
      """

    sublayers = [
      sql: "select * from wdpapoly_july2014_0"
      cartocss: cartocss
    ]
    carto_tiles = new cartodb.Tiles(
      sublayers: sublayers
      user_name: "carbon-tool"
    )
    carto_tiles.getTiles( (o) =>
      L.tileLayer(o.tiles[0]).addTo(@map)
    )

  fitToBounds: (bounds, withPadding) ->
    # If a protected area overlaps the antimeridian ST_Extent does not 
    # return a correct bounding box (Ideas to fix this?)
    # So, assuming that no protected areas real bbox width is bigger than 300,
    # if this is the case correct to a fixed 10 degree width.
    if Math.abs(bounds[0][1]) + Math.abs(bounds[1][1]) > 300
      bounds[1][1] = -170
    opts = {}
    if withPadding?
      padding = @calculatePadding()
      opts.paddingTopLeft = padding.topLeft
      opts.paddingBottomRight = padding.bottomRight

    @map.fitBounds(bounds, opts)

  setZoomControl: (position) ->
    @map.addControl(L.control.zoom(position: position))

  locate: ->
    @map.locate(setView: true)

  calculatePadding: ->
    mapSize = @map.getSize()
    paddingLeft = mapSize.x/5
    {topLeft: [paddingLeft, 50], bottomRight: [0, 50]}
