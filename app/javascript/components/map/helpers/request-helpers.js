import axios from 'axios'

const instance = axios.create()

delete instance.defaults.headers.common['X-CSRF-Token']

export const axiosGetWithoutCSRF = (url, cb) => {
  instance.get(url).then(cb)
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
    instance.get(this.currentService.url + this.getQueryString(
        this.currentService.isPoint,
        this.currentService.queryString || ''
      ))
      .then(this.handlePointQueryResponse.bind(this))
  }

  handlePointQueryResponse (res) {
    const hasFoundArea = this.cb(res)

    if(!hasFoundArea && this.n < this.nMax) {
      this.currentService = this.services[++this.n]
      this.queryAllServices()
    }
  }

  getQueryString (isPoint, additionalQueryParams='') {
    // let queryString = `/query?geometry=${this.coords.lng}%2C+${this.coords.lat}&geometryType=esriGeometryPoint&returnGeometry=false&inSR=4326&outFields=site_id,site_pid%2Cname&f=json`
    let queryString = `/query?geometry=${this.coords.lng}%2C+${this.coords.lat}&geometryType=esriGeometryPoint&returnGeometry=false&inSR=4326&outFields=wdpaid,wdpa_pid%2Cname&f=json`

    if (additionalQueryParams) { 
      queryString += '&' + additionalQueryParams
    }
  
    if (isPoint) {
      const distanceInMiles = 5

      queryString += `&distance=${distanceInMiles}&units=esriSRUnit_StatuteMile`
    }
  
    return queryString
  }
}
