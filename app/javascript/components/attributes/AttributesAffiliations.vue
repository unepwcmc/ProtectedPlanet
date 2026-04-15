<template>
  <div class="card--stats-affiliations" :class="$attrs.class">
    <h2 class="card__h2" v-text="title" />
    <template v-if="forPdf">
      <div class="card__all-attributes" v-if="hasAnyAffiliations">
        <AttributesAffiliationsSub
          v-for="(links, sitePid) in affiliationsByParcel"
          :key="sitePid"
          :links="links"
          :sub-title="subTitle ? `${subTitle}: ${sitePid}` : undefined"
          :translations="translations"
        />
      </div>
      <p v-else>{{ translations.no_information }}</p>
    </template>
    <template v-else>
      <AttributesAffiliationsSub
        v-if="currentAffiliationLinks.length > 0"
        :links="currentAffiliationLinks"
        :translations="translations"
      />
      <p v-else>{{ translations.no_information }}</p>
    </template>
  </div>
</template>

<script>
import AttributesAffiliationsSub from './AttributesAffiliationsSub.vue'
import parcelSelectionListener from '../../mixins/parcelSelectionListener'

export default {
  name: 'AttributesAffiliations',

  components: {
    AttributesAffiliationsSub
  },

  props: {
    // Flat list of affiliation objects, each { site_pid, affiliation, image_url, link_url, ... }
    affiliations: {
      type: Array,
      required: true,
      default: () => []
    },
    title: {
      type: String,
      required: true,
      default: undefined
    },
    subTitle: {
      type: String,
      default: undefined
    },
    forPdf: {
      type: Boolean,
      default: false
    },
    translations: {
      type: Object,
      required: true,
      default: () => ({
        no_information: 'No information available'
      })
    }
  },

  data () {
    return {
      selectedParcelId: null
    }
  },

  mixins: [parcelSelectionListener],

  computed: {
    currentAffiliationLinks () {
      const selectedParcelId = this.selectedParcelId
      if (!selectedParcelId) return []
      const aff = this.affiliations || []
      return aff.filter(l => String(l.site_pid) === String(selectedParcelId))
    },

    affiliationsByParcel () {
      const aff = this.affiliations || []
      const affiliationAttributesByParcel = {}
      aff?.forEach(affiliationAttributes => {
        const site_pid = affiliationAttributes?.site_pid

        if (!affiliationAttributesByParcel[site_pid]) 
          affiliationAttributesByParcel[site_pid] = []

        affiliationAttributesByParcel[site_pid].push(affiliationAttributes)
      })
      return affiliationAttributesByParcel
    },

    hasAnyAffiliations () {
      return (this.affiliations || []).length > 0
    }
  },

  methods: {
    onParcelSelected (parcelId) {
      this.selectedParcelId = parcelId
    }
  }
}
</script>
