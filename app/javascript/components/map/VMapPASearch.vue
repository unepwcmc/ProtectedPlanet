<template>
  <div class="v-map-pa-search">
    <div class="v-map-pa-search__autocomplete">
      <autocomplete
        :key="autocompleteKey"
        v-model="autoCompleteResults"
        :placeholder="searchType.placeholder"
        :autocomplete-callback="autocompleteCallback"
        :error-messages="autocompleteErrorMessages"
        @submit="emitZoomToEvent"
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
    }
  },

  watch: {
    searchType () {
      this.autocompleteKey ++
    }
  },

  methods: {
    /**
     * Initiate the event for pan & zoom.
     * @param search the search term to be used with the map query
     * @return void
     */
    emitZoomToEvent (search) {
      this.$eventHub.$emit('map:zoom-to', {
        addPopup: search.value.is_pa, 
        name: search.value.title,
        ...search.value
      })
    }
  }
}
</script>