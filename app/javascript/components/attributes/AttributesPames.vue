<template>
  <div class="card--attributes-pame" :class="$attrs.class">
    <h2 class="card__h2" v-text="title" />
    <template v-if="forPdf" >
        <AttributesPame
          class="card__all-attributes"
          v-for="(pameAttributes, sitePid) in pamesAttributesList" :key="sitePid"
          :pameAttributes="pameAttributes"
          :title="subTitleForShowingAllEntries(sitePid)"
          :translations="translations"
        />
    </template>
    <template v-else>
      <AttributesPame
        :pameAttributes="currentPameAttributes"
        :translations="translations"
      />
    </template>
  </div>
</template>

<script>
import AttributesPame from './AttributesPame.vue'
import parcelSelectionListener from '../../mixins/parcelSelectionListener'

export default {
  name: 'AttributesPames',

  components: {
    AttributesPame
  },

  props: {
    // { site_pid => { method => [years...] } }
    pamesAttributesList: {
      type: Object,
      required: true,
      default: () => ({})
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
    currentPameAttributes () {
      // Use selected parcel if set, otherwise fall back to first parcel
      const activeParcelId = this.selectedParcelId || (Object.keys(this.list || {})[0])
      return this.pamesAttributesList[activeParcelId] || {}
    }
  },

  methods: {
    onParcelSelected (parcelId) {
      this.selectedParcelId = parcelId
    },
    subTitleForShowingAllEntries (sitePid) {
      return `${this.subTitle}: ${sitePid}`
    }
  }
}
</script>
