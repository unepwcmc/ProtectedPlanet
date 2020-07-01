<template>
  <div 
    :id="id"
    class="map__mapbox" 
  />
</template>

<script>
export default {
  name: 'VMap',

  data () {
    return {
      id: 'map-target',
      mapbox: {
        accessToken: process.env.MAPBOX_ACCESS_TOKEN,
      }
    }
  },

  mounted () {
    mapboxgl.accessToken =  this.mapbox.accessToken
    
    const map = new mapboxgl.Map({
      container: this.id,
      style: 'mapbox://styles/mapbox/streets-v11'
    })
map.on('load', () => {
this.mapServer()
//this.addLoads(100)
//this.addSingleArea(555557228)
    })
    this.map = map
  },

methods: {

mapServer(){
  this.map.addLayer({
            "id": "dynamic-demo",
            "type": "raster",
            "minzoom": 0,
            "maxzoom": 22,
            "source": {
                "type": "raster",
            "tiles": ['https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/MapServer/tile/{z}/{y}/{x}'],
                "tileSize": 256
            }
  });
},

addSingleArea(wdpaid){
  this.map.addLayer({
    'id': 'dummy',
    'type': 'fill',
    'source': {
    'type': 'geojson',
    'data':
'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/FeatureServer/1/query?where=wdpaid%3D'+wdpaid+'&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&having=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&f=geojson'
     },
    'paint': {
    'fill-color': 'rgba(200, 100, 240, 0.3)',
    'fill-outline-color': 'rgba(200, 100, 240, 1)'
     }
  })
},

addLoads(max){
  this.map.addLayer({
    'id': 'dummy',
    'type': 'fill',
    'source': {
    'type': 'geojson',
    'data':
'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/FeatureServer/1/query?where=wdpaid<'+max+'&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&having=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&f=geojson'
    },
    'paint': {
    'fill-color': 'rgba(200, 100, 240, 0.3)',
    'fill-outline-color': 'rgba(200, 100, 240, 1)'
    }
  })
}


}
}
</script>
