<template>
  <div class="v-map-pa-search">
    <div class="v-map-pa-search__dropdown">
      {{ dropdownLabel }}
      <selector
        v-bind="{ 
          options: dropdownOptions, 
          value: searchType.id 
        }"
        @change="onDropdownChange"
      />
    </div>
    <div class="v-map-pa-search__autocomplete">
      <autocomplete
        v-model="autoCompleteResults"
        :placeholder="searchType.placeholder"
        @search="getAutocompleteResults"
      />
    </div>
  </div>
</template>

<script>
import Autocomplete from '../autocomplete/Autocomplete'
import Selector from '../select/Selector'

import axios from 'axios'

export default {
  name: 'VMapPASearch',
  components: {
    Autocomplete,
    Selector
  },
  props: {
    dropdownLabel: {
      type: String,
      required: true
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
        })
    }
  },

  data() {
    return {
      autoCompleteResults: [],
      searchType: this.searchTypes[0],
    }
  },

  computed: {
    dropdownOptions() {
      return this.searchTypes.map(type =>
        this.convertSearchTypeToDropdownOption(type)
      )
    },
  },

  methods: {
    convertSearchTypeToDropdownOption(searchType) {
      return {
        label: searchType.title,
        value: searchType.id
      }
    },

    getAutocompleteResults(searchTerm) {
      console.log({searchTerm})
      setTimeout(() => {
        this.autoCompleteResults = [
          'a',
          'abc',
          'abcde',
          'a',
          'abc',
          'abcde',
          'a',
          'abc',
          'abcde',
          'a',
          'abc',
          'abcde'
        ]
      }, 500)
      // axios.post('/search/autocomplete', {
      //   type: this.searchType.id,
      //   search_term: searchTerm
      // }).then(results => {
      //   this.autoCompleteResults = results
      // })
    },

    onDropdownChange(value) {
      console.log({onDropdownChange: value})
      this.searchType = this.searchTypes.filter(type => type.id === value)[0]
    },

    submitSearch(search) {
      this.$emit('change', search)
    }
  }
}
</script>