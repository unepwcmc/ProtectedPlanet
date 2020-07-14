import axios from 'axios'

const instance = axios.create()

delete instance.defaults.headers.common['X-CSRF-Token']

export const getCountryExtentByISO3 = (iso3, cb) => {
  instance.get(`https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=GID_0+%3D+%27${iso3}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson`).then(cb)
}

export const getRegionExtentByName = (name, cb) => {
  instance.get(`https://data-gis.unep-wcmc.org/server/rest/services/AdministrativeUnits/GADM_EEZ_Layer/FeatureServer/0/query?where=region+%3D+%27${encodeURIComponent(name)}%27&returnGeometry=false&returnExtentOnly=true&outSR=4326&f=pjson`).then(cb)
}
