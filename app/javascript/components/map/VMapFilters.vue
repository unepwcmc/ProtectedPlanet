<template>
  <div
    v-if="show"
    class="v-map-filters"
  >
    <v-map-header
      v-model="title"
      closeable
      @close="onClose"
    />
    <div class="v-map-filters__body">
      <v-map-pa-search-dropdown
        :label="dropdownLabel"
        :options="dropdownOptions"
        :value="searchType.id"
        @change="onDropdownChange"
      />
      <v-map-pa-search
        :type="searchType"
        @search="onSearch"
      />
      <div class="v-map-filters__overlays">
        <div
          v-for="(overlay, index) in overlays"
          :key="index"
          class="v-map-filters__overlay"
        >
          <v-map-filter v-bind="overlay" />
        </div>
      </div>

      <div
        v-if="disclaimer"
        class="v-map-disclaimer"
      >
        <div class="v-map-disclaimer__heading">
          {{ disclaimer.heading }}
        </div>
        <div
          class="v-map-disclaimer__body"
          v-html="disclaimer.body"
        />
      </div>
    </div>
  </div>
</template>
<script>
import VMapFilter from './VMapFilter'
import VMapHeader from './VMapHeader'
import VMapPASearch from './VMapPASearch'
import VMapPASearchDropdown from './VMapPASearchDropdown'

export default {
  name: 'VMapFilters',

  components: {
    VMapFilter,
    VMapHeader,
    'v-map-pa-search': VMapPASearch,
    'v-map-pa-search-dropdown': VMapPASearchDropdown
  },

  props: {
    overlays: {
      type: Array,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    dropdownLabel: {
      type: String,
      required: true
    },
    disclaimer: {
      type: Object,
      required: true,
      validator: type => {
        return (
          type.hasOwnProperty('heading') &&
          typeof type.heading === 'string' &&
          type.hasOwnProperty('body') &&
          typeof type.heading === 'string'
        )
      }
    },
    searchTypes: {
      type: Array,
      required: true,
      validator: types =>
        types.every(type => {
          return (
            type.hasOwnProperty('id') &&
            type.hasOwnProperty('title') &&
            type.hasOwnProperty('placeholder') &&
            typeof type.id === 'string' &&
            typeof type.title === 'string' &&
            typeof type.placeholder === 'string'
          )
        }),
    }
  },

  data() {
    return {
      show: true,
      searchType: this.searchTypes[0]
    }
  },

  computed: {
    dropdownOptions() {
      return this.searchTypes.map(type =>
        this.convertSearchTypeToDropdownOption(type)
      )
    }
  },

  methods: {
    convertSearchTypeToDropdownOption(searchType) {
      return {
        label: searchType.title,
        value: searchType.id
      }
    },

    onClose() {
      this.show = false
      this.$emit('show', false)
    },

    onSearch(query) {
      console.log({ query })
    },

    onDropdownChange(value) {
      // set the original search type from its dropdown-compatible option
      this.searchType = this.searchTypes[
        this.searchTypes.map(type => type.id).indexOf(value)
      ]
    }
  }
}
</script>
