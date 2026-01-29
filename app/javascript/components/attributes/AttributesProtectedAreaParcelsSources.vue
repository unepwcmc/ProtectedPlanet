<template>
  <div class="card--feault-block sm-sources pdf-break-inside-avoid" :class="$attrs.class">
    <h2 class="card__h2">{{ translations.title }} ({{ forPdf ? totalCount : currentSources.length }})</h2>
    <template v-if="forPdf">
      <AttributesProtectedAreaParcelSource
        class="card__all-attributes"
        v-for="(sources, sitePid) in sourcesAttributesList"
        :key="sitePid"
        :sourceAttributes="sources || []"
        :title="subTitleForShowingAllEntries(sitePid)"
        :translations="translations"
      />
    </template>
    <template v-else>
      <AttributesProtectedAreaParcelSource
        :sourceAttributes="currentSources"
        :translations="translations"
      />
    </template>
  </div>
</template>

<script>
import AttributesProtectedAreaParcelSource from './AttributesProtectedAreaParcelSource.vue'
import parcelSelectionListener from '../../mixins/parcelSelectionListener'

export default {
  name: 'AttributesProtectedAreaParcelsSources',

  components: {
    AttributesProtectedAreaParcelSource
  },

  props: {
    /**
     * Object keyed by site_pid with array of sources per parcel.
     * Each source: { title, date_updated, resp_party }
     */
    sourcesAttributesList: {
      type: Object,
      required: true,
      default: () => ({})
    },
    forPdf: {
      type: Boolean,
      default: false
    },
    subTitle: {
      type: String,
      default: undefined
    },
    translations: {
      type: Object,
      required: true,
      default: () => ({})
    }
  },

  mixins: [parcelSelectionListener],

  data () {
    return {
      selectedParcelId: null
    }
  },

  computed: {
    currentSources () {
      const activeParcelId = this.selectedParcelId || (Object.keys(this.sourcesAttributesList || {})[0])
      return this.sourcesAttributesList[activeParcelId] || []
    },
    totalCount () {
      return Object.values(this.sourcesAttributesList || {}).reduce((sum, sources) => sum + (sources?.length || 0), 0)
    }
  },

  methods: {
    onParcelSelected (parcelId) {
      this.selectedParcelId = parcelId
    },
    subTitleForShowingAllEntries (sitePid) {
      return this.subTitle ? `${this.subTitle}: ${sitePid}` : sitePid
    }
  }
}
</script>

