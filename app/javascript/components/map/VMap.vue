<template>
  <div 
    :id="mapboxOptions.container"
    class="map__mapbox" 
  />
</template>

<script>
import { getFirstForegroundLayerId } from './helpers/map-helpers'
import mixinAddLayers from './mixins/mixin-add-layers'

export default {
  name: 'VMap',

  mixins: [mixinAddLayers],

  props: {
    initBoundingBox: {
      type: Array, // e.g. [[xmin,ymin],[xmax,ymax]]
      default: null
    }
  },

  data () {
    return {
      accessToken: process.env.MAPBOX_ACCESS_TOKEN,
      firstForegroundLayerId: '',
      map: {},
      mapboxOptions: {
        container: 'map-target',
        style: 'mapbox://styles/mapbox/streets-v11'
      }
    }
  },

  mounted () {
    this.initMap()
  },

  methods: {
    initMap () {
      this.setMapOptions()
      this.map = new mapboxgl.Map(this.mapboxOptions)
      this.addEventHandlersToMap()
    },

    setMapOptions () {
      mapboxgl.accessToken =  this.accessToken

      if (this.initBoundingBox) { 
        this.mapboxOptions.bounds = this.initBoundingBox 
      }
    },

    addEventHandlersToMap () {
      this.map.on('style.load', () => {
        this.setFirstForegroundLayerId()
      })

      if(this.onClick) {
        this.map.on('click', e => { this.onClick(e) })
      }

      //FOR TESTING ONLY!
      this.map.on('load', () => {
        this.mapServer()
        // this.addLoads(100)
        // this.addSingleArea(555557228)
      })
    },

    setFirstForegroundLayerId () {
      this.firstForegroundLayerId = getFirstForegroundLayerId(this.map)
    },
  }
}
</script>
