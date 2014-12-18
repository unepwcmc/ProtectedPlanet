define('bounds', [], ->
  class Bounds
    @setToBounds: (map, config) ->
      boundFrom = config['boundFrom']
      boundTo = config['boundTo']

      if boundFrom? and boundTo?
        withPadding = config['paddingEnabled']
        @_fitToBounds(
          map,
          [boundFrom, boundTo],
          withPadding
        )

    @_fitToBounds: (map, bounds, withPadding) ->
      opts = {}
      if withPadding?
        padding = @_calculatePadding(map)
        opts.paddingTopLeft = padding.topLeft
        opts.paddingBottomRight = padding.bottomRight

      map.fitBounds(@_normalizeBounds(bounds), opts)

    @_calculatePadding: (map) ->
      mapSize = map.getSize()
      paddingLeft = mapSize.x/5
      {topLeft: [paddingLeft, 50], bottomRight: [0,70]}

    @_calculateBoundWidth: (bounds) ->
      x1 = bounds[0][1]
      x2 = bounds[1][1]
      if x1 < 0 and x2 >= 0
        return Math.abs(x1) + Math.abs(x2)
      else
        max = Math.max(Math.abs(x1), Math.abs(x2))
        min = Math.min(Math.abs(x1), Math.abs(x2))
        return max - min

    @_normalizeBounds: (bounds) ->
      # If a protected area overlaps the antimeridian ST_Extent does not
      # return a correct bounding box (Ideas to fix this?)
      # So, assuming that no protected areas real bbox width is bigger than 300,
      # if this is the case correct to a fixed 10 degree width.
      if @_calculateBoundWidth(bounds) > 300
        bounds[1][1] = -170
      bounds

  return Bounds
)
