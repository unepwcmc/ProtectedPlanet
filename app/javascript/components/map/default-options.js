export const BASELAYERS_DEFAULT = [
  {
    id: 'terrain',
    name: 'Terrain',
    style: 'mapbox://styles/unepwcmc/cko1hsfi50vog17l697cr4d6p'
  },
  {
    id: 'satellite',
    name: 'Satellite',
    style: 'mapbox://styles/unepwcmc/ckniq2twg0q3b17s5gqfxhagf'
  }
]
export const RTL_TEXT_PLUGIN_URL = 'https://api.mapbox.com/mapbox-gl-js/plugins/mapbox-gl-rtl-text/v0.2.3/mapbox-gl-rtl-text.js'
export const MAP_OPTIONS_DEFAULT = {
  container: 'map-target',
  scrollZoom: false,
  attributionControl: false,
  preserveDrawingBuffer: true, // needed for PDF rendering
  zoom: 1.3,
  maxZoom: 10 // Maximum zoom where tiles are cached for the web-map service
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