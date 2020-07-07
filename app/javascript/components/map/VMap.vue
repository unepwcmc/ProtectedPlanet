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
import { containsObjectWithId } from '../../helpers/array-helpers'

import VMapBaselayerControls from './VMapBaselayerControls'
import mixinAddLayers from './mixins/mixin-add-layers'
import mixinControls from './mixins/mixin-controls'
import mixinLayers from './mixins/mixin-layers'
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

  mixins: [
    mixinAddLayers,
    mixinControls,
    mixinPaPopup,
    mixinLayers
  ],

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
    },

    visibleLayers () {
      return this.$store.state.map.visibleLayers
    }
  },

  watch: {
    visibleLayers(newLayers, oldLayers) {
      const layersToHide = oldLayers.filter(oL => 
        !containsObjectWithId(newLayers, oL.id)
      )

      this.hideLayers(layersToHide)
      this.showLayers(newLayers)
    }
  },

  mounted () {
    this.initMap()
  },

  methods: {
    initMap () {
      /* eslint-disable no-undef */
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
    },

    updateBaselayer (baselayer) {
      console.log(`New baselayer: ${baselayer.id}`)
    },

    showLayers (layers) {
      layers.forEach(l => this.showLayer(l))
    },

    showLayer(layer) {
      const mapboxLayer = this.map.getLayer(layer.id)
      const isVisible = mapboxLayer && mapboxLayer.visibility === 'visible'

      if (!mapboxLayer) {
        this.addLayerBeneathBoundariesAndLabels(layer)
      } else if (!isVisible) {
        this.setLayerVisibility(layer, true)
      }
    },

    addLayerBeneathBoundariesAndLabels (layer) {
      let attempts = 0

      const interval = setInterval(() => {
        attempts++

        if (this.firstForegroundLayerId || attempts > 10) {
          clearInterval(interval)
          this.addLayer(layer)
        }
      }, 200)
    },

    addLayer(layer) {
      if (true) {//layer type goes here
        this.addTypeLayer(layer)
      }
    },

    hideLayers(layers) {
      this.setLayerVisibilities(layers, false)
    },

    setLayerVisibilities(layers, isVisible) {
      layers.forEach(l => {
        this.setLayerVisibility(l, isVisible)
      })
    },

    setLayerVisibility(layer, isVisible) {
      const layerId = layer.id
      const visibility = isVisible ? 'visible' : 'none'

      if (this.map.getLayer(layerId)) {
        this.map.setLayoutProperty(layerId, 'visibility', visibility)
      }
    },

  }
}
</script>
