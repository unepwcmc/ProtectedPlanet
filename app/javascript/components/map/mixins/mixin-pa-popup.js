export default {
  methods: {
    onClick (e) {
      const coords = e.lngLat
      const params = {
        lon: coords.lng,
        lat: coords.lat,
        distance: 1
      }

      console.log('Now I would check for pas with these params', params)
      const popup = new mapboxgl.Popup({className: 'v-map-pa-popup'})
        .setLngLat(e.lngLat)
        .setHTML("<div>Here be a Protected Area</div>")
        .setMaxWidth("300px")
        .addTo(this.map);
    }
  }
}