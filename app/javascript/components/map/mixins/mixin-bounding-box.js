import { getWithoutCSRF } from '../helpers/request-helpers'

export default {
  data () {
    return {
      initBounds: null
    }
  },

  methods: {
    initBoundingBoxAndMap () {  
      if (this.mapOptions.boundsUrl) {
        getWithoutCSRF(
          this.mapOptions.boundsUrl.url, 
          this.getExtentResponseHandler(this.mapOptions.boundsUrl.isPoint)
        )
      } else {
        this.initMap()
      }
    },

    getExtentResponseHandler (isPoint=false) {
      const padding = isPoint ? 5 : 0
      
      return res => {
        const extent = res.data.extent
  
        if (extent) {
          this.initBounds = [
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
  
        this.initMap()
      }
    }
  }
}