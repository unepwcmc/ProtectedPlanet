<template>
  <div 
    :id="containerId"
    class="map__mapbox" 
  />
</template>

<script>
import { getFirstForegroundLayerId } from './helpers/map-helpers'
import mixinAddLayers from './mixins/mixin-add-layers'
import mixinControls from './mixins/mixin-controls'

const MAP_OPTIONS_DEFAULT = {
  container: 'map-target',
  style: 'mapbox://styles/mapbox/streets-v11',
  //bounds: [[xmin,ymin],[xmax,ymax]],
}
const CONTROLS_OPTIONS_DEFAULT = {
  showZoom: true,
  showCompass: false
}
const EMPTY_OPTIONS = {
  map: {},
  controls: {}
}

export default {
  name: 'VMap',

  mixins: [mixinAddLayers, mixinControls],

  props: {
    options: {
      type: Object,
      default: () => EMPTY_OPTIONS
    }
  },

  data () {
    return {
      accessToken: process.env.MAPBOX_ACCESS_TOKEN,
      containerId: MAP_OPTIONS_DEFAULT.container,
      firstForegroundLayerId: '',
      map: {},
      mapOptions: {},
      controlsOptions: {}
    }
  },

  created () {
    this.setOptions()
  },

  mounted () {
    this.initMap()
  },

  methods: {
    setOptions () {
      mapboxgl.accessToken =  this.accessToken
      this.mapOptions = {
        ...MAP_OPTIONS_DEFAULT,
        ...this.options.map
      }
      this.controlsOptions = {
        ...CONTROLS_OPTIONS_DEFAULT,
        ...this.options.controls
      }
    },

    initMap () {
      this.map = new mapboxgl.Map(this.mapOptions)
      this.addControls()
      this.addEventHandlersToMap()
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

    showLayers(layerIds) {
      this.setLayerVisibilities(layerIds, true)
    },

    hideLayers(layerIds) {
      this.setLayerVisibilities(layerIds, false)
    },

    setLayerVisibilities(layerIds, isVisible) {
      layerIds.forEach(id => {
        this.setLayerVisibility(id, isVisible)
      })
    },

    setLayerVisibility(layerId, isVisible) {
      const visibility = isVisible ? 'visible' : 'none'

      if (this.map.getLayer(layerId)) {
        this.map.setLayoutProperty(layerId, 'visibility', visibility)
      }
    },

  }
}
</script>
