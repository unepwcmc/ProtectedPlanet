<template>
  <div class="v-map">
    <div :id="containerId" class="map__mapbox" />
    <v-map-baselayer-controls
      v-if="controlsOptions.showBaselayerControls"
      :baselayers="baselayers"
    />
  </div>
</template>

<script>
import { containsObjectWithId } from '../../helpers/array-helpers'
import { executeAfterCondition } from '../../helpers/timing-helpers'
import { 
  BASELAYERS_DEFAULT, 
  CONTROLS_OPTIONS_DEFAULT, 
  EMPTY_OPTIONS, 
  MAP_OPTIONS_DEFAULT, 
  RTL_TEXT_PLUGIN_URL
} from './default-options'

import VMapBaselayerControls from './VMapBaselayerControls'
import mixinAddLayers from './mixins/mixin-add-layers'
import mixinControls from './mixins/mixin-controls'
import mixinLayers from './mixins/mixin-layers'
import mixinPaPopup from './mixins/mixin-pa-popup'
import mixinBoundingBox from './mixins/mixin-bounding-box'

export default {
  name: 'VMap',

  components: { VMapBaselayerControls },

  mixins: [
    mixinAddLayers,
    mixinBoundingBox,
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

  data() {
    return {
      accessToken: process.env.MAPBOX_ACCESS_TOKEN,
      containerId: MAP_OPTIONS_DEFAULT.container,
      map: {},
    }
  },

  computed: {
    baselayers() {
      return this.options.baselayers || BASELAYERS_DEFAULT
    },

    controlsOptions() {
      return {
        ...CONTROLS_OPTIONS_DEFAULT,
        ...this.options.controls
      }
    },

    mapOptions() {
      const options = {
        ...MAP_OPTIONS_DEFAULT,
        ...this.options.map,
        style: this.baselayers[0].style,
      }

      if (this.initBounds) {
        options.bounds = this.initBounds
      }

      return options
    },

    selectedBaselayer() {
      return this.$store.state.map.selectedBaselayer
    },

    visibleLayers() {
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
    },

    selectedBaselayer() {
      this.executeAfterStyleLoad(() => {
        this.map.setStyle(this.selectedBaselayer.style)
        this.showLayers(this.visibleLayers)
      })
    }
  },

  mounted() {
    this.initBoundingBoxAndMap()
  },

  methods: {
    initMap() {
      /* eslint-disable no-undef */
      mapboxgl.accessToken = this.accessToken
      // Add support for RTL languages
      mapboxgl.setRTLTextPlugin(
        RTL_TEXT_PLUGIN_URL, 
        null, 
        true // Lazy loading
      )
      this.map = new mapboxgl.Map(this.mapOptions)
      this.addControls()
      this.addEventHandlersToMap()
    },

    addEventHandlersToMap() {
      this.$eventHub.$on('map:resize', () => this.map.resize())

      this.map.on('style.load', () => {
        this.setFirstForegroundLayerId()
      })

      if (this.onClick) {
        this.map.on('click', e => {
          if (e.originalEvent.detail === 1) {
            this.onClick(e)
          }
        })
      }
    },

    showLayers(layers) {
      this.executeAfterStyleLoad(() => {
        layers.forEach(l => this.showLayer(l))
      })
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

    addLayerBeneathBoundariesAndLabels(layer) {
      executeAfterCondition(
        () => this.firstForegroundLayerId,
        () => { this.addLayer(layer) },
        10
      )
    },

    addLayer(layer) {
      if (layer.type === 'raster_tile') {
        this.addRasterTileLayer(layer)
      } else if (layer.type === 'raster_data') {
        this.addRasterDataLayer(layer)
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