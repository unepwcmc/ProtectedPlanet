export const BASELAYERS_DEFAULT = [
  {
    id: 'terrain',
    name: 'Terrain',
    style: 'mapbox://styles/unepwcmc/ckek07ou668y019lzobq4gv5a'
  },
  {
    id: 'satellite',
    name: 'Satellite',
    style: 'mapbox://styles/unepwcmc/ckek09j5n0j2r19qmvey6tux6'
  }
]
export const MAP_OPTIONS_DEFAULT = {
  container: 'map-target',
  scrollZoom: false,
  attributionControl: false,
  bounds: [[-180, -90], [180, 90]]
  //boundingISO: ISO3,
  //boundingRegion; Name e.g. Europe,
}
export const CONTROLS_OPTIONS_DEFAULT = {
  showZoom: true,
  showCompass: false,
  showBaselayerControls: true,
  attributionLocation: 'bottom-left'
}
export const EMPTY_OPTIONS = {
  map: null,
  controls: null,
  baselayers: null
}