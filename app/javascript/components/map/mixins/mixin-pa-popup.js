import axios from 'axios'
import { setAxiosHeaders } from '../../../helpers/axios-helpers'

setAxiosHeaders(axios)

export default {
  methods: {
    onClick (e) {
      const coords = e.lngLat
      const params = {
        lon: coords.lng,
        lat: coords.lat,
        distance: 1
      }

      axios.get('/api/v3/search/by_point', params)
        .then(res => {
          if (res.data.length > 0) {
            this.addPopup(coords, res.data[0])
          } else { //TODO: remove when we know the api works
            this.addPopup(coords, {wdpa_id: '1', name: 'A protected area'})
          }
        })
    },

    addPopup (coords, pa) {
      // eslint-disable-next-line no-undef
      new mapboxgl.Popup({className: 'v-map-pa-popup'})
        .setLngLat(coords)
        .setHTML(`<a href="/${pa.wdpa_id}">${pa.name}</a>`)
        .setMaxWidth('300px')
        .addTo(this.map)
    }
  }
}