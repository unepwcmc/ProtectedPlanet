export const BASELAYERS_DEFAULT = [
  {
    id: 'terrain',
    name: 'Terrain',
    style: 'mapbox://styles/unepwcmc/ckfy4y2nm0vqn19mkcmiyqo73'
  },
  {
    id: 'satellite',
    name: 'Satellite',
    style: 'mapbox://styles/unepwcmc/ckfy4tzxq0vq719lgi34s2lad'
  }
]
export const MAP_OPTIONS_DEFAULT = {
  container: 'map-target',
  scrollZoom: false,
  attributionControl: false,
  preserveDrawingBuffer: true, // needed for PDF rendering
  zoom: 1.3,
  //bounds: [[-180, -90], [180, 90]],
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