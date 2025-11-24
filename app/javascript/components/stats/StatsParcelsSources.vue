<template>
  <div class="card--stats-sources sm-sources pdf-break-inside-avoid">
    <h2 class="card__h2">{{ translations.title }} ({{ currentSources.length }})</h2>
    <div class="card__content flex">
      <ol class="list--underline-sources">
        <li class="list__li" v-for="(source, index) in currentSources" :key="index">
          <span class="list__title">{{ source.title }}</span>
          <span class="list__date">{{ translations.updated }}: {{ source.date_updated }}</span>
          <span class="list__party">{{ source.resp_party }}</span>
        </li>
      </ol>
    </div>


  </div>
</template>

<script>
export default {
  name: "StatsSourcesParcel",
  props: {
    sources: {
      type: Object,
      required: true,
      default: () => ({})
    },
    small: {
      type: Boolean,
      default: false
    },
    translations: {
      type: Object,
      required: true,
      default: () => ({})
    }
  },
  data() {
    return {
      selectedParcelId: null
    }
  },
  computed: {
    currentSources() {
      if (!this.selectedParcelId) {
        // If no parcel is selected, show all sources from all parcels
        return this.getAllSources()
      }
      
      // Return sources for the selected parcel
      return this.sources[this.selectedParcelId] || []
    }
  },
  methods: {
    getAllSources() {
      // Flatten all sources from all parcels
      const allSources = []
      Object.values(this.sources).forEach(parcelSources => {
        if (Array.isArray(parcelSources)) {
          allSources.push(...parcelSources)
        }
      })
      return allSources
    },
    onParcelSelected(parcelId) {
      this.selectedParcelId = parcelId
    }
  },
  mounted() {
    // Listen for parcel selection events from the parent or other components
    this.$root.$on('parcel-selected', this.onParcelSelected)
    
    // Set initial parcel selection if there's only one parcel
    const parcelIds = Object.keys(this.sources)
    if (parcelIds.length === 1) {
      this.selectedParcelId = parcelIds[0]
    }
  },
  beforeDestroy() {
    this.$root.$off('parcel-selected', this.onParcelSelected)
  }
}
</script>

