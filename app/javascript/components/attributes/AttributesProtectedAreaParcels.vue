<template>
  <div class="card--attributes-pa-and-parcels">
    <h2 class="card__h2" v-text="title" />
    <div v-if="forPdf" class="card__all-attributes">
      <div v-for="(parcelAttributes, index) in attributesList" :key="`${index}parcelAttributesList`">
        <AttributesProtectedAreaParcel :attributes="parcelAttributes.attributes" :showSitePid="true" />
      </div>
    </div>
    <template v-else>
      <AttributesProtectedAreaParcel :attributes="currentAttrbiteSet" :showSitePid="false" />
    </template>
  </div>
</template>

<script>
import AttributesProtectedAreaParcel from './AttributesProtectedAreaParcel.vue'
import parcelSelectionListener from '../../mixins/parcelSelectionListener'

export default {
  name: "statsAttributes",
  components: { AttributesProtectedAreaParcel },
  props: {
    title: {
      type: String,
      required: true,
      default: undefined
    },
    forPdf: {
      type: Boolean,
      default: false
    },
    attributesList: {
      type: Array,
      required: true,
      default: () =>[]
    }
    /**
     *
     *  {
     *    site_pid: string
     *    attributes: {
     *      title: string
     *      value: string 
     *    }[]
     *  }[]
     * 
     */
  },
  data() {
    return {
      selectedParcelId: null,
    }
  },
  mixins: [parcelSelectionListener],
  computed: {
    currentAttrbiteSet() {
      const chosenAttributeSet = this.attributesList
        .find((attributeInfo) => attributeInfo.site_pid === this.selectedParcelId)
      return chosenAttributeSet?.attributes ?? []
    }
  },
  methods: {
    onParcelSelected (parcelId) {
      this.selectedParcelId = parcelId
    }
  }
}
</script>