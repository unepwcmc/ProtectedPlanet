<template>
  <div 
    :id="id" 
  />
</template>

<script>
export default {
  name: 'v-map',

  props: {
    
    // mapboxToken: {
    //   type: String,
    //   required: true
    // }
  },

  data () {
    return {
      id: 'map-target',
      mapbox: {
        // accessToken: this.mapboxToken,
      }
    }
  },

  mounted () {
    // mapboxgl.accessToken =  this.mapbox.accessToken
    
    // const map = new mapboxgl.Map({
    //   container: this.id,
    //   style: 'mapbox://styles/mapbox/streets-v11'
    // })

    // this.map = map
  },

  methods: {

  }
}
</script>