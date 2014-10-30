window.ProtectedPlanet ||= {}

class ProtectedPlanet.HomeMap extends ProtectedPlanet.ProtectedAreaMap
  constructor: (@map, @config) ->
    @startAnimation()

  startAnimation: ->
    panMap = => @map.panBy(new L.Point(0.5, 0))
    interval = setInterval(panMap, 300)

    @map.on('dragstart', -> clearInterval(interval))
    @map.on('zoomstart', -> clearInterval(interval))
