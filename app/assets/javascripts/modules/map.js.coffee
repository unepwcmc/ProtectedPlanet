window.ProtectedPlanet ||= {}

class ProtectedPlanet.Map
  constructor: (@$mapContainer, map_class) ->
    return false if @$mapContainer.length == 0

    @config = @$mapContainer.data()
    @map = L.map($mapContainer.attr('id'),
      {zoomControl: false, scrollWheelZoom: false})

    @addBaseLayer()
    @addZoomControl()
    @setToBounds()

    return new map_class(@map, @config)

  addBaseLayer: ->
    terrain = L.tileLayer('http://api.tiles.mapbox.com/v3/unepwcmc.ijh17499/{z}/{x}/{y}.png')
    terrain.addTo(@map)
    satellite = L.tileLayer('http://api.tiles.mapbox.com/v3/unepwcmc.k2p9jhk8/{z}/{x}/{y}.png')

    L.control.layers(
      "Terrain": terrain,
      "Satellite": satellite
    ).addTo(@map)

  addZoomControl: ->
    position = @config['zoomControl']
    if position?
      @map.addControl(L.control.zoom(position: position))

  setToBounds: ->
    boundFrom = @config['boundFrom']
    boundTo = @config['boundTo']

    if boundFrom? and boundTo?
      withPadding = @config['paddingEnabled']
      @fitToBounds(
        [boundFrom, boundTo],
        withPadding
      )

  fitToBounds: (bounds, withPadding) ->
    opts = {}
    if withPadding?
      padding = @calculatePadding()
      opts.paddingTopLeft = padding.topLeft
      opts.paddingBottomRight = padding.bottomRight

    @map.fitBounds(@normalizeBounds(bounds), opts)

  calculatePadding: ->
    mapSize = @map.getSize()
    paddingLeft = mapSize.x/5
    {topLeft: [paddingLeft, 50], bottomRight: [0,70]}

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
