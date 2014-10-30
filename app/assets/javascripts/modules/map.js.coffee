window.ProtectedPlanet ||= {}

class ProtectedPlanet.Map
  constructor: (@$mapContainer, map_class) ->
    return false if @$mapContainer.length == 0

    @config = @$mapContainer.data()
    L.mapbox.accessToken = 'pk.eyJ1IjoidW5lcHdjbWMiLCJhIjoiRXg1RERWRSJ9.taTsSWwtAfFX_HMVGo2Cug'

    @map = L.mapbox.map(
      $mapContainer.attr('id'),
      'unepwcmc.ijh17499',
      {minZoom: 2, zoomControl: false, attributionControl: false}
    )

    @addBaseLayer()
    @addZoomControl()
    @setToBounds()

    return new map_class(@map, @config)

  addBaseLayer: ->
    terrain = L.mapbox.tileLayer('unepwcmc.ijh17499')
    satellite = L.mapbox.tileLayer('unepwcmc.k2p9jhk8')

    L.control.layers(
      "Terrain": terrain,
      "Satellite": satellite
    ).addTo(@map)

  addZoomControl: ->
    @map.addControl(L.control.zoom(position: 'topright'))

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
