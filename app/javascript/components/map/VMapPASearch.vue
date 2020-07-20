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
        :key="autocompleteKey"
        v-model="autoCompleteResults"
        :placeholder="searchType.placeholder"
        :autocomplete-callback="autocompleteCallback"
        :error-messages="autocompleteErrorMessages"
        @submit="submitSearch"
      />
    </div>
  </div>
</template>

<script>
import { setAxiosHeaders } from '../../helpers/axios-helpers'
import axios from 'axios'
import Autocomplete from '../autocomplete/Autocomplete'
import Selector from '../select/Selector'

setAxiosHeaders(axios)

export default {
  name: 'VMapPASearch',
  components: {
    Autocomplete,
    Selector
  },
  props: {
    autocompleteErrorMessages: {
      required: true,
      type: Object
    },
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

  data () {
    return {
      /**
       * The array of strings to be populated from an autocomplete response.
       * @type Array
       */
      autoCompleteResults: [],
      /**
       * The search type should be an object with an id, title and placeholder text.
       * @type Object
       */
      searchType: this.searchTypes[0],

      /**
       * Key used to determine whether to refresh the autocomplete component.
       */
      autocompleteKey: 0
    }
  },

  computed: {
    /**
     * The callback is used with the autocomplete component to fetch results.
     * It will receive the search to be used in the fetch as an argument.
     * It must return a Promise that resolves to an array of strings.
     * @return Function
     */
    autocompleteCallback () {
      return searchTerm => {
        return new Promise((resolve, reject) => {
          axios.post('/search/autocomplete', {
            type: this.searchType.id,
            search_term: searchTerm
          })
            .then(response => {
              /**
               * Map results to autocomplete-compatible objects.
               * Autocomplete expects an array of label/value objects.
               */ 
              const results = response.data.map(item => ({
                label: item.title,
                value: item
              }))

              resolve(Promise.resolve(results))
            })
            .catch(e => reject(Promise.reject(e)))
        })
      }
    },

    /**
     * Dropdown options are computed because their searchType equivalents
     * do not have a compatible object structure with a label and value.
     * @return Array dropdown-compatible searchTypes
     */
    dropdownOptions () {
      return this.searchTypes.map(type =>
        this.convertSearchTypeToDropdownOption(type)
      )
    },
  },

  watch: {
    searchType () {
      this.autocompleteKey ++
    }
  },

  methods: {
    /**
     * The dropdown expects an array with objects containing a label and value.
     * @param searchType the searchType to convert to a dropdown option.
     * @return Object dropdown option
     */
    convertSearchTypeToDropdownOption (searchType) {
      return {
        label: searchType.title,
        value: searchType.id
      }
    },

    /**
     * Update the search type based on the selector's choice.
     * @param value the [id] of a searchType
     * @return void
     */
    onDropdownChange (value) {
      this.searchType = this.searchTypes.filter(type => type.id === value)[0]
    },

    /**
     * Emit the search term refined by the autocomplete.
     * @param search the search term to be used with the map query
     * @return void
     */
    submitSearch (search) {
      this.$emit('change', search)
    }
  }
}
</script>