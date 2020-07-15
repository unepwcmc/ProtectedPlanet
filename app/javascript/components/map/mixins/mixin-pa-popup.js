import { getOECMFromCoords, getWDPAPointFromCoords, getWDPAPolyFromCoords } from '../helpers/request-helpers'

export default {
  methods: {
    onClick (e) {
      const coords = e.lngLat

      getOECMFromCoords(coords, res => {
        const oecm = this.addPopupIfFound(res, coords)

        if (!oecm) {
          getWDPAPointFromCoords(coords, res => {
            const pa = this.addPopupIfFound(res, coords)

            if(!pa) {
              getWDPAPolyFromCoords(coords, res => {
                this.addPopupIfFound(res, coords)
              })
            }
          })
        }
      })
    },

    addPopupIfFound (res, coords) {
      const features = res.data.features
      let pa = null

      if (features.length) {
        pa = features[0].attributes

        this.addPopup(coords, pa)
      }

      return pa
    },

    addPopup (coords, pa) {
      const html = pa.wdpaid ? 
        `<a href="/${pa.wdpaid}">${pa.name}</a>` :
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