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

    getBoundsFromExtent (extent, padding=5) {
      const isDateLineSplit = extent.xmin < 0 & extent.xmax > 0
      return [
        [
          isDateLineSplit? extent.xmax - padding : Math.max(extent.xmin - padding, -180),
          Math.max(extent.ymin - padding, -90)
        ],
        [
          isDateLineSplit? extent.xmax + padding : Math.min(extent.xmax + padding, 180),
          Math.min(extent.ymax + padding, 90)
        ]
      ]
    }
  }
}