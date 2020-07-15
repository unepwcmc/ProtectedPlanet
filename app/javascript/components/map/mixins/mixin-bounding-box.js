import { getCountryExtentByISO3, getPAExtentByWDPAId, getRegionExtentByName } from '../helpers/request-helpers'

export default {
  data () {
    return {
      initBounds: null
    }
  },

  methods: {
    initBoundingBoxAndMap () {  
      if (this.mapOptions.boundingISO) {
        getCountryExtentByISO3(this.mapOptions.boundingISO, this.getExtentResponseHandler())
      } else if (this.mapOptions.boundingRegion) {
        getRegionExtentByName(this.mapOptions.boundingRegion, this.getExtentResponseHandler())
      } else if (this.mapOptions.boundingWDPAId) {
        getPAExtentByWDPAId(
          this.mapOptions.boundingWDPAId, 
          this.mapOptions.isPoint,
          this.getExtentResponseHandler(1)
        )
      } else {
        this.initMap()
      }
    },

    getExtentResponseHandler (padding=5) {
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