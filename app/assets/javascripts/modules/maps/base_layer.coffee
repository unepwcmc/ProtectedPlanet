define('base_layer', [], ->
  class BaseLayer
    @render: (map) ->
      terrain = L.mapbox.tileLayer('unepwcmc.l8gj1ihl')
      satellite = L.mapbox.tileLayer('unepwcmc.lac5fjl1')

      L.control.layers(
        "Terrain": terrain,
        "Satellite": satellite
      ).addTo(map)

  return BaseLayer
)
