<template>
  <div>
    <div 
      :id="containerId"
      class="map__mapbox" 
    />
    <v-map-baselayer-controls 
      v-if="controlsOptions.showBaselayerControls"
      :baselayers="baselayers"
      @update:baselayer="updateBaselayer" 
    />
  </div>
</template>

<script>
import { getFirstForegroundLayerId } from './helpers/map-helpers'
import VMapBaselayerControls from './VMapBaselayerControls'
import mixinAddLayers from './mixins/mixin-add-layers'
import mixinControls from './mixins/mixin-controls'
import mixinPaPopup from './mixins/mixin-pa-popup'

const MAP_OPTIONS_DEFAULT = {
  container: 'map-target',
  style: 'mapbox://styles/mapbox/streets-v11',
  //bounds: [[xmin,ymin],[xmax,ymax]],
}
const CONTROLS_OPTIONS_DEFAULT = {
  showZoom: true,
  showCompass: false,
  showBaselayerControls: true
}
const BASELAYERS_DEFAULT = [{id: 'Terrain'}, {id: 'Satellite'}]
const EMPTY_OPTIONS = {
  map: null,
  controls: null,
  baselayers: null
}

export default {
  name: 'VMap',

  components: {VMapBaselayerControls},

  mixins: [mixinAddLayers, mixinControls, mixinPaPopup],

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
    }
  },

  computed: {
    baselayers () {
      return this.options.baselayers || BASELAYERS_DEFAULT
    },
    
    controlsOptions () {
      return {
        ...CONTROLS_OPTIONS_DEFAULT,
        ...this.options.controls
      }
    },

    mapOptions () {
      return {
        ...MAP_OPTIONS_DEFAULT,
        ...this.options.map
      }
    }
  },

  mounted () {
    this.initMap()
  },

  methods: {
    initMap () {
      mapboxgl.accessToken = this.accessToken
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

    updateBaselayer (baselayer) {
      console.log(`New baselayer: ${baselayer.id}`)
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
