import { axiosGetWithoutCSRF } from '../helpers/request-helpers'

export default {
  data () {
    return {
      initBounds: null
    }
  },

  created () {
    this.addZoomEventListener()
  },

  methods: {
    addZoomEventListener () {
      this.$eventHub.$on('map:zoom-to', this.zoomTo)
    },

    initBoundingBoxAndMap () {  
      if (this.mapOptions.boundsUrl) {
        axiosGetWithoutCSRF(
          this.mapOptions.boundsUrl.url, 
          this.getExtentResponseHandler(this.mapOptions.boundsUrl.padding)
        )
      } else {
        this.initMap()
      }
    },

    getExtentResponseHandler (padding) {      
      return res => {
        const extent = res.data.extent

        if (extent) {
          this.initBounds = this.getBoundsFromExtent(extent, padding)
        }
  
        this.initMap()
      }
    },

    zoomTo (options) {
      axiosGetWithoutCSRF(
        options.extent_url.url, 
        this.getZoomAndPopupHandler(options)
      )
    },

    getZoomAndPopupHandler (options) {
      return res => {
        const extent = res.data.extent

        if (!extent) { 
          return 
        }

        this.fitMapToBounds(extent, options.extent_url.padding)

        if (options.name && options.addPopup) {
          this.addPopupFromExtent(extent, options)
        }
      }
    },

    fitMapToBounds (extent, padding) {
      this.map.fitBounds(this.getBoundsFromExtent(extent, padding))
    },

    addPopupFromExtent (extent, options) {
      const coords = {
        lng: (extent.xmin + extent.xmax)/2,
        lat: (extent.ymin + extent.ymax)/2
      }

      //Requires mixin-pa-popup.js
      this.addPopup(coords, options)
    },

    getBoundsFromExtent (extent, padding=[5,5,5]) {
      // handle PAs split by the int date line
      const isDateLineSplit = extent.xmin < 179 & extent.xmax > 179
      return [
        [
          isDateLineSplit? 180 - padding[0] : Math.max(extent.xmin - padding[0], -180),
          Math.max(extent.ymin - padding[2], -90)
        ],
        [
          isDateLineSplit? 180 + padding[1] : Math.min(extent.xmax + padding[1], 180),
          Math.min(extent.ymax + padding[2], 90)
        ]
      ]
    }
  }
}