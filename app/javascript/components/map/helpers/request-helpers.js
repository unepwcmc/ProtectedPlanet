import axios from 'axios'

const instance = axios.create()

delete instance.defaults.headers.common['X-CSRF-Token']

export const getCountryExtentByISO3 = (iso3, cb) => {
  instance.get(`https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=GID_0+%3D+%27${iso3}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson`).then(cb)
}

export const getRegionExtentByName = (name, cb) => {
  instance.get(`https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=region+%3D+%27${encodeURIComponent(name)}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson`).then(cb)
}

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

export const getOECMFromCoords = (coords, cb) => {
  instance.get(oecmFeatureServerPolyUrl + getQueryString(coords))
    .then(cb)
}

export const getWDPAPolyFromCoords = (coords, cb) => {
  instance.get(wdpaFeatureServerPolyUrl + getQueryString(coords))
    .then(cb)
}

export const getWDPAPointFromCoords = (coords, cb) => {
  instance.get(wdpaFeatureServerPointUrl + getQueryString(coords, 5))
    .then(cb)
}