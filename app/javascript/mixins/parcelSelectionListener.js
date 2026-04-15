export default {
  mounted () {
    if (this.$root && typeof this.onParcelSelected === 'function') {
      this.$root.$on('parcel-selected', this.onParcelSelected)
    }
  },

  beforeDestroy () {
    if (this.$root && typeof this.onParcelSelected === 'function') {
      this.$root.$off('parcel-selected', this.onParcelSelected)
    }
  }
}

