export default {
  methods: {
    addControls () {
      if (this.controlsOptions.showZoom) {
        this.addZoomControls()
      }
    },

    addZoomControls () {
      this.map.addControl(
        //eslint-disable-next-line no-undef
        new mapboxgl.NavigationControl({
          showCompass: this.controlsOptions.showCompass
        })
      )
    }
  }
}