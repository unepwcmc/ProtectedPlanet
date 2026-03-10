<template>
  <div class="card--feault-block" v-if="showDropdown">
    <div class="card__top">
      <h2 class="card__h2" v-text="title" />
      <span v-if="showDescription" v-text="description" />
    </div>
    <dropdown
      class="card--attributes-parcels-dropdown"
      v-model="chosenParcelId"
      :title="dropdownTitle"
      :options="sitePids"
    />
  </div>
</template>

<script>
import Dropdown from '../dropdown/Dropdown.vue'

export default {
  name: 'AttributesParcelsDropdown',
  components: { Dropdown },

  props: {
    title: {
      type: String,
      required: true,
      default: undefined
    },
    description: {
      type: String,
      required: false,
      default: undefined
    },
    dropdownTitle: {
      type: String,
      default: undefined
    },
    sitePids: {
      type: Array,
      required: true,
      default: () => []
    },
    parcelIdParam: {
      type: String,
      required: false
    },
    forPdf: {
      type: Boolean,
      required: false,
      default: false
    }
  },

  data () {
    return {
      chosenParcelId: undefined
    }
  },

  computed: {
    moreThanOneParcels () {
      return this.sitePids.length > 1
    },
    showDropdown () {
      return this.moreThanOneParcels && !this.forPdf
    },
    showDescription () {
      return this.moreThanOneParcels && !!this.description
    },
  },

  watch: {
    chosenParcelId (newParcelId) {
      if (!newParcelId) return
      
      if(!this.forPdf) {
        // Update URL parameter using the centralized parameter name
        const urlParams = new URLSearchParams(window.location.search)
        urlParams.set(this.parcelIdParam, newParcelId)
        const newUrl = `${window.location.pathname}?${urlParams.toString()}`
        window.history.replaceState({ page: 1 }, null, newUrl)
      }
      
      // Emit parcel selection event to root so other components (AttributesProtectedAreaParcels,
      // AttributesPames, StatsParcelsSources) can react.
      this.$root.$emit('parcel-selected', newParcelId)
    }
  },

  mounted () {
    if (this.sitePids.length > 0) {

      // Check URL for parcel ID parameter using the centralized parameter name
      const urlParams = new URLSearchParams(window.location.search)
      const pidFromUrl = urlParams.get(this.parcelIdParam)
      
      // Use pid from URL if it exists in sitePids, otherwise default to first parcel
      if (pidFromUrl && this.sitePids.includes(pidFromUrl) && !this.forPdf) {
        this.chosenParcelId = pidFromUrl
      } else {
        this.chosenParcelId = this.sitePids[0]
      }
      
      this.$root.$emit('parcel-selected', this.chosenParcelId)
    }
  }
}
</script>
