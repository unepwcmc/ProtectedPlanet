<template>
  <div class="card--stats-attributes">
    <div class="card__top">
      <h2 class="card__h2" v-text="title" />
      <span v-if="showDescription" v-text="description" />
    </div>
    <dropdown v-if="showDropdown" v-model="chosenPacelId" :title="dropdownTitle" :options="options" />
    <div v-if="showAllAttributes" class="card__all-attributes">
      <div v-for="(attributes, index) in allAttributesInfo" :key="`${index}attributesInfo`">
        <StatsAttributes  :attributes="attributes" />
      </div>
    </div>
    <template v-else>
      <StatsAttributes :attributes="currentAttrbiteSet" />
    </template>
  </div>
</template>

<script>
import Dropdown from '../dropdown/Dropdown.vue'
import StatsAttributes from './StatsAttributes.vue'

export default {
  name: "statsAttributes",
  components: { Dropdown, StatsAttributes },
  props: {
    title: {
      type: String,
      required: true,
      default: undefined
    },
    description: {
      type: String,
      required: true,
      default: undefined
    },
    dropdownTitle: {
      type: String,
      default: undefined
    },
    showAllAttributes: {
      type: Boolean,
      default: false
    },
    attributesInfo: {
      type: Array,
      required: true,
      default: () =>[]
    }
    /**
     *
     *  {
     *    wdpa_pid: string
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
      chosenPacelId: undefined,
    }
  },
  beforeMount() {
    if (this.attributesInfo.length > 0 ) {
      // No matter what condition we are displaying first parcel 
      this.chosenPacelId = this.attributesInfo[0].wdpa_pid
    }
  },
  computed: {
    showDescription() {
      return this.moreThanOneParcels && !this.showAllAttributes
    },
    showDropdown() {
      return this.moreThanOneParcels && !this.showAllAttributes
    },
    allAttributesInfo() {
      return this.attributesInfo.map((attributeInfo) => {
        return [
          { title: this.dropdownTitle, value: attributeInfo.wdpa_pid },
          ...attributeInfo.attributes
        ]
      })
    },
    options() {
      return this.attributesInfo.map((attributeInfo) => attributeInfo.wdpa_pid)
    },
    moreThanOneParcels() {
      return this.attributesInfo.length > 1
    },
    currentAttrbiteSet() {
      const chosenAttributeSet = this.attributesInfo
        .find((attributeInfo) => attributeInfo.wdpa_pid === this.chosenPacelId)
      return chosenAttributeSet?.attributes ?? []
    }
  }
}
</script>