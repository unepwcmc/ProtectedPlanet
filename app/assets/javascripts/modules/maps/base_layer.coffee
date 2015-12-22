define('base_layer', [], ->
  class BaseLayer
    @render: (map, opts={}) ->
      terrain = L.mapbox.tileLayer('unepwcmc.l8gj1ihl')
      satellite = L.mapbox.tileLayer('unepwcmc.lac5fjl1')

      L.control.layers({
        "Terrain": terrain,
        "Satellite": satellite
      }, null, {
        position: opts.controlPosition || 'topleft'
      }).addTo(map)

  return BaseLayer
)
