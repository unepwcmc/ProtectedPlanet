import { PointQuery } from '../helpers/request-helpers'
const MARKER_HEIGHT = 18
const MARKER_HALF_WIDTH = 7

export default {
  props: {
    servicesForPointQuery: {
      type: Array,
      default: () => []
    }
  },

  data () {
    return {
      markers: [],
      popups: [],
      popupOffsets: {
        'top': [0, 1],
        'top-left': [0,1],
        'top-right': [0,1],
        'bottom': [0, -MARKER_HEIGHT-20],
        'bottom-left': [0, -MARKER_HEIGHT-1],
        'bottom-right': [0, -MARKER_HEIGHT-1],
        'left': [MARKER_HALF_WIDTH+1, -MARKER_HEIGHT/2],
        'right': [-MARKER_HALF_WIDTH-1, -MARKER_HEIGHT/2]
      }
    }
  },

  methods: {
    onClick (e) {
      this.removeAllMarkersAndPopups()

      const coords = e.lngLat

      new PointQuery(
        this.servicesForPointQuery, 
        coords, 
        this.addPopupIfFound(coords)
      ).queryAllServices()
    },

    removeAllMarkersAndPopups () {
      this.markers.forEach(marker => { marker.remove() })
      this.markers = []

      this.popups.forEach(popup => { popup.remove() })
      this.popups = []
    },

    addPopupIfFound (coords) {
      return res => {
        const features = res.data.features
        let pa = null
  
        if (features.length) {
          pa = features[0].attributes
  
          this.addPopup(coords, {
            url: `/${pa.wdpaid}`,
            name: pa.name
          })
        }

        return pa !== null
      }
    },

    addPopup (coords, pa) {
      this.removeAllMarkersAndPopups()

      const html = pa.url ? 
        `<a href="${pa.url}">${pa.name}</a>` :
        `<a>${pa.name}</a>`
      const pin = document.createElement('div')

      pin.className = 'v-map-pin'

      // eslint-disable-next-line no-undef
      this.popups.push(new mapboxgl.Popup({
        className: 'v-map-pa-popup', 
        closeButton: false, 
        offset: this.popupOffsets
      }).setLngLat(coords)
        .setHTML(html)
        .setMaxWidth('300px')
        .addTo(this.map)
      )

      // eslint-disable-next-line no-undef
      this.markers.push(new mapboxgl.Marker({element: pin, anchor: 'bottom'})
        .setLngLat(coords)
        .addTo(this.map)
      )
    }
  }
}