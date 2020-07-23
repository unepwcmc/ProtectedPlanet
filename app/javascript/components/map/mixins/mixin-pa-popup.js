import { PointQuery } from '../helpers/request-helpers'

export default {
  props: {
    servicesForPointQuery: {
      type: Array,
      default: () => []
    }
  },

  methods: {
    onClick (e) {
      const coords = e.lngLat

      new PointQuery(
        this.servicesForPointQuery, 
        coords, 
        this.addPopupIfFound(coords)
      ).queryAllServices()
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
      const html = pa.url ? 
        `<a href="${pa.url}">${pa.name}</a>` :
        `<a>${pa.name}</a>`

      // eslint-disable-next-line no-undef
      new mapboxgl.Popup({className: 'v-map-pa-popup'})
        .setLngLat(coords)
        .setHTML(html)
        .setMaxWidth('300px')
        .addTo(this.map)
    }
  }
}