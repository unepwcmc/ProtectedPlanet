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
  //THESE METHODS ARE FOR TESTING ONLY
  methods: {
    addRasterTileLayer (layer) {
      console.log('Adding raster layer:', layer)

      this.map.addLayer({
        id: layer.id,
        type: 'raster',
        minzoom: 0,
        maxzoom: 22,
        source: {
          type: 'raster',
          tiles: [layer.url],
          tileSize: 256,
        },
        layout: {
          visibility: 'visible'
        }
      }, this.firstForegroundLayerId)
    },

    addRasterDataLayer(layer) {
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
      console.log('Adding data layer:', layer, options, this.firstForegroundLayerId)
      this.map.addLayer(options, this.firstForegroundLayerId)
    },
  },
}
