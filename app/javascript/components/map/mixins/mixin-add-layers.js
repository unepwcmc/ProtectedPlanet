const addPaintOptions = (options, layer) => {
  if (layer.isPoint) {
    options['type'] = 'circle'
    options['paint'] = { 
      'circle-radius': [
        'interpolate',
        ['exponential', 1],
        ['zoom'],
        0, 1.5,
        6, 4
      ],
      'circle-color': layer.color,
      'circle-opacity': 0.7
    }
  } else {
    options['type'] = 'fill'
    options['paint'] = {
      'fill-color': layer.color,
      'fill-opacity': 0.8,
    }
  }
}

export default {

  methods: {
    addRasterTileLayer (layer) {
      if(!this.hasExistingMapLayer(layer.id)) {
        this.map.addLayer({
          id: layer.id,
          type: 'raster',
          minzoom: 0,
          maxzoom: 22,
          source: {
            type: 'raster',
            tiles: [layer.url]
          },
          layout: {
            visibility: 'visible'
          }
        }, this.firstForegroundLayerId)
      }
    },

    addRasterDataLayer(layer) {
      if(!this.hasExistingMapLayer(layer.id)) {
        const options = {
          id: layer.id,
          source: {
            type: 'geojson',
            data: layer.url
          },
          layout: {
            visibility: 'visible'
          }
        }
        
        addPaintOptions(options, layer)

        this.map.addLayer(options, this.firstForegroundLayerId) 
      }
    },

    hasExistingMapLayer (id) {
      const existingMapLayer = this.map.getLayer(id)

      return typeof existingMapLayer !== 'undefined'
    }
  },
}
