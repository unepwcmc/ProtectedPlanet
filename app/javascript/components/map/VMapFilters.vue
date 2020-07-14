<template>
  <div v-if="show" class="v-map-filters">
    <v-map-header closeable v-model="title" @close="onClose" />
  <div
    v-if="show"
    class="v-map-filters"
    :class="{'v-map-filters--hidden': isHidden}"
  >
    <v-map-header 
      v-model="title"
      closeable
      @close="onClose"
    />
    <div class="v-map-filters__body">
      <v-map-pa-search-dropdown
        :state="convertSearchTypeToDropdownOption(searchType)"
        :label="dropdownLabel"
        :options="dropdownOptions"
        @change="onDropdownChange"
      />
      <v-map-pa-search @search="onSearch" :type="searchType" />
      <div class="v-map-filters__overlays">
        <div v-for="(overlay, index) in overlays" :key="index" class="v-map-filters__overlay">
          <v-map-filter v-bind="overlay" />
        </div>
      </div>


      <v-map-disclaimer
        v-if="disclaimer"
        class="v-map-disclaimer--embedded"
        :disclaimer="disclaimer"
      />
    </div>
  </div>
</template>
<script>
import VMapDisclaimer from './VMapDisclaimer'
import VMapFilter from "./VMapFilter";
import VMapHeader from "./VMapHeader";
import VMapPASearch from "./VMapPASearch";
import VMapPASearchDropdown from "./VMapPASearchDropdown";


import { disableTabbing } from '../../helpers/focus-helpers'

export default {
  name: "VMapFilters",

  components: {
    VMapDisclaimer,
    VMapFilter,
    VMapHeader,
    "v-map-pa-search": VMapPASearch,
    "v-map-pa-search-dropdown": VMapPASearchDropdown
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
      required: false,
      validator: type => {
        return (
          type.hasOwnProperty("heading") &&
          typeof type.heading === "string" &&
          type.hasOwnProperty("body") &&
          typeof type.heading === "string"
        );
      }
    },
    searchTypes: {
      type: Array,
      required: true,
      validator: types =>
        types.every(type => {
          return (
            type.hasOwnProperty("id") &&
            type.hasOwnProperty("title") &&
            type.hasOwnProperty("placeholder") &&
            typeof type.id === "string" &&
            typeof type.title === "string" &&
            typeof type.placeholder === "string"
          );
        }),
      default: null
    },
    isHidden: {
      type: Boolean,
      default: false
    }
  },

  computed: {
    dropdownOptions() {
      return this.searchTypes.map(type =>
        this.convertSearchTypeToDropdownOption(type)
      );
    }
  },

  data() {
    return {
      show: true,
      searchType: this.searchTypes[0]
    };
  },
  
  mounted () {
    disableTabbing(this.$el)
  },

  methods: {
    convertSearchTypeToDropdownOption(searchType) {
      return {
        label: searchType.title,
        value: searchType.id
      };
    },
    onClose() {
      this.show = false;
      this.$emit("show", false);
    },

    onSearch(query) {
      console.log({ query });
    },

    onDropdownChange(value) {
      // set the original search type from its dropdown-compatible option
      this.searchType = this.searchTypes[
        this.searchTypes.map(type => type.id).indexOf(value)
      ];
    }
  }
};
</script>
