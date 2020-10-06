export const BASELAYERS_DEFAULT = [
  {
    id: 'terrain',
    name: 'Terrain',
    style: 'mapbox://styles/unepwcmc/ck6hsqzns0vx31iqxdcgccgow'
  },
  {
    id: 'satellite',
    name: 'Satellite',
    style: 'mapbox://styles/unepwcmc/ckc4wrxs114iq1in4u273ks4q'
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