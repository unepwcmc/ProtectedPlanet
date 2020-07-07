export default {
  //THESE METHODS ARE FOR TESTING ONLY
  methods: {
    addTypeLayer () {
      console.log('adding a layer of type type beneath layer', this.firstForegroundLayerId)

      // const options = {
      //   'id': layer.id,
      //   'type': 'raster',
      //   'minzoom': 0,
      //   'maxzoom': 22,
      //   'source': {
      //     'type': 'raster',
      //     'tiles': [layer.tileset],
      //     'tileSize': 64
      //   },
      //   'paint': {
      //     'raster-hue-rotate': 0
      //   }
      // }

      // this.map.addLayer(options, nextLayerId)
    },

    mapServer() {
      this.map.addLayer({
        id: 'dynamic-demo',
        type: 'raster',
        minzoom: 0,
        maxzoom: 22,
        source: {
          type: 'raster',
          tiles: [
            'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/MapServer/tile/{z}/{y}/{x}',
          ],
          tileSize: 256,
        },
      })
    },

    addSingleArea(wdpaid) {
      this.map.addLayer({
        id: 'dummy',
        type: 'fill',
        source: {
          type: 'geojson',
          data:
            'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/FeatureServer/1/query?where=wdpaid%3D' +
            wdpaid +
            '&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&having=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&f=geojson',
        },
        paint: {
          'fill-color': 'rgba(200, 100, 240, 0.3)',
          'fill-outline-color': 'rgba(200, 100, 240, 1)',
        },
      })
    },

    addLoads(max) {
      this.map.addLayer({
        id: 'dummy',
        type: 'fill',
        source: {
          type: 'geojson',
          data:
            'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/FeatureServer/1/query?where=wdpaid<' +
            max +
            '&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&having=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&f=geojson',
        },
        paint: {
          'fill-color': 'rgba(200, 100, 240, 0.3)',
          'fill-outline-color': 'rgba(200, 100, 240, 1)',
        },
      })
    },
  },
}
