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

    this.map = map
  },

  methods: {

  }
}
</script>