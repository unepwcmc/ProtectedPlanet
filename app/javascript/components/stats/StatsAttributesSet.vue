<template>
  <div class="card--stats-attributes">
    <div class="card__top">
      <h2 class="card__h2" v-text="title" />
      <span v-if="showDescription" v-text="description" />
    </div>
    <dropdown v-if="showDropdown" v-model="chosenPacelId" :title="dropdownTitle" :defaultDropdownText="defaultDropdownText" :options="options" />
    <div v-if="showAllAttributes" class="card__all-attributes">
      <div v-for="(attributes, index) in attributesInfoForPdf" :key="`${index}attributesInfoModified`">
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
    defaultDropdownText:{
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
     *    wpda_pid: string
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
    if (this.attributesInfoModified.length === 1 ) {
      this.chosenPacelId = this.attributesInfoModified[0].wpda_pid
    }
  },
  computed: {
    showDescription() {
      return this.moreThanOneParcels && !this.showAllAttributes
    },
    showDropdown() {
      return this.moreThanOneParcels && !this.showAllAttributes
    },
    attributesInfoModified() {
      // TODO: Delete here
      this.attributesInfo[0].attributes[0].value = "Pacific Rim National Park Reserve Of Canada_A"
      this.attributesInfo[1].attributes[0].value = "Pacific Rim National Park Reserve Of Canada_B"
      return this.attributesInfo
    },
    attributesInfoForPdf() {
      return this.attributesInfoModified.map((attributeInfo) => {
        return [
          { title: this.dropdownTitle, value: attributeInfo.wpda_pid },
          ...attributeInfo.attributes
        ]
      })
    },
    options() {
      return this.attributesInfoModified.map((attributeInfo) => attributeInfo.wpda_pid)
    },
    moreThanOneParcels() {
      return this.attributesInfoModified.length > 1
    },
    currentAttrbiteSet() {
      const chosenAttributeSet = this.attributesInfoModified
        .find((attributeInfo) => attributeInfo.wpda_pid === this.chosenPacelId)
      return chosenAttributeSet?.attributes ?? []
    }
  }
}
</script>