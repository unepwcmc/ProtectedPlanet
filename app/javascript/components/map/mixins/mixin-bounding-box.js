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
      if (this.mapOptions.bounds) {
        // User hardcoded bounds for dateline countries, because the API we
        // use returns min/max longitudes of -180 and +180.
        this.initBounds = this.mapOptions.bounds
        this.initMap()
      } else if (this.mapOptions.boundsUrl) {
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

      return [
        [
          Math.max(extent.xmin - padding, -180), 
          Math.max(extent.ymin - padding, -90)
        ],
        [
          Math.min(extent.xmax + padding, 180), 
          Math.min(extent.ymax + padding, 90)
        ]
      ]
    }
  }
}