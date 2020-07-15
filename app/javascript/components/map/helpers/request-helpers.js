import axios from 'axios'

const instance = axios.create()

delete instance.defaults.headers.common['X-CSRF-Token']

//TODO: Move services and point vs poly logic to backend

export const getCountryExtentByISO3 = (iso3, cb) => {
  instance.get(`https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=GID_0+%3D+%27${iso3}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson`).then(cb)
}

export const getRegionExtentByName = (name, cb) => {
  instance.get(`https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=region+%3D+%27${encodeURIComponent(name)}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson`).then(cb)
}

export const getPAExtentByWDPAId = (wdpaId, isPoint, cb) => {
  const layerNumber = isPoint ? 0 : 1

  instance.get(`https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/FeatureServer/${layerNumber}/query?where=wdpaid+%3D+%27${wdpaId}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson`).then(cb)
} 

export class PointQuery {
  constructor(services, coords, cb) {
    this.cb = cb
    this.coords = coords
    this.nMax = services.length - 1
    this.n = 0
    this.services = services
    this.currentService = this.services[0]
  }

  queryAllServices () {
    instance.get(this.currentService.url + this.getQueryString(this.currentService.isPoint))
      .then(this.handlePointQueryResponse.bind(this))
  }

  handlePointQueryResponse (res) {
    const hasFoundArea = this.cb(res)

    if(!hasFoundArea && this.n < this.nMax) {
      this.currentService = this.services[++this.n]
      this.queryAllServices()
    }
  }

  getQueryString (isPoint) {
    let queryString = `query?geometry=${this.coords.lng}%2C+${this.coords.lat}&geometryType=esriGeometryPoint&returnGeometry=false&inSR=4326&outFields=wdpaid%2Cname&f=json`
  
    if (isPoint) {
      const distanceInMiles = 5

      queryString += `&distance=${distanceInMiles}&units=esriSRUnit_StatuteMile`
    }
  
    return queryString
  }
}
