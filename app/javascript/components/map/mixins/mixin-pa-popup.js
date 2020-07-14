import axios from 'axios'

const wdpaFeatureServerUrl = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/FeatureServer/'
const wdpaFeatureServerPointUrl = wdpaFeatureServerUrl + '0/'
const wdpaFeatureServerPolyUrl  = wdpaFeatureServerUrl + '1/'
const oecmFeatureServerPolyUrl = 'https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/FeatureServer/0/'

const getQueryString = (coords, distanceInMiles=null) => {
  let queryString = `query?geometry=${coords.lng}%2C+${coords.lat}&geometryType=esriGeometryPoint&returnGeometry=false&inSR=4326&outFields=wdpaid%2Cname&f=json`

  if (distanceInMiles) {
    queryString += `&distance=${distanceInMiles}&units=esriSRUnit_StatuteMile`
  }

  return queryString
}

export default {
  methods: {
    onClick (e) {
      const coords = e.lngLat

      // axios.get(oecmFeatureServerPolyUrl + getQueryString(coords))
      //   .then(res => { this.addPopupIfFound(res, coords) })
      // axios.get(wdpaFeatureServerPointUrl + getQueryString(coords, 5))
      //   .then(res => { this.addPopupIfFound(res, coords) })
      // axios.get(wdpaFeatureServerPolyUrl + getQueryString(coords))
      //   .then(res => { this.addPopupIfFound(res, coords) })


      axios.get(oecmFeatureServerPolyUrl + getQueryString(coords))
        .then(res => {
          const oecm = this.addPopupIfFound(res, coords)

          if (!oecm) {
            axios.get(wdpaFeatureServerPointUrl + getQueryString(coords, 5))
              .then(res => {
                const pa = this.addPopupIfFound(res, coords)

                if(!pa) {
                  axios.get(wdpaFeatureServerPolyUrl + getQueryString(coords))
                    .then(res => {
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