import { axiosGetWithoutCSRF } from '../helpers/request-helpers'

export default {
  data () {
    return {
      initBounds: null
    }
  },

  methods: {
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

    zoomTo (boundsUrl) {
      axiosGetWithoutCSRF(
        boundsUrl.url, 
        this.getExtentResponseZoomToHandler(boundsUrl.padding)
      )
    },

    getExtentResponseZoomToHandler (padding) {
      return res => {
        const extent = res.data.extent
  
        if (extent) {
          this.map.fitBounds(this.getBoundsFromExtent(extent, padding))
        }
      }
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