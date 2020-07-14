import { getCountryExtentByISO3, getRegionExtentByName } from '../helpers/request-helpers'

export default {
  data () {
    return {
      initBounds: null
    }
  },

  methods: {
    initBoundingBoxAndMap () {  
      if (this.mapOptions.boundingISO) {
        getCountryExtentByISO3(this.mapOptions.boundingISO, this.handleExtentResponse)
      } else if (this.mapOptions.boundingRegion) {
        getRegionExtentByName(this.mapOptions.boundingRegion, this.handleExtentResponse)
      } else {
        this.initMap()
      }
    },

    handleExtentResponse (res) {
      const extent = res.data.extent
      const padding = 5

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