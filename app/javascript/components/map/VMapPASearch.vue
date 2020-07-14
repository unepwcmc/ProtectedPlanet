<template>
  <div class="v-map-pa-search__container">
    <div
      class="v-map-pa-search"
      @focus="onElementFocus"
    >
      <input
        ref="input"
        v-model="query"
        class="v-map-pa-search__input"
        type="text"
        :placeholder="type.placeholder"
        @input="onInput"
        @keyup="onKeyup"
        @keyup.enter.prevent.stop="onEnter"
        @keyup.esc.prevent.stop="onEscape"
      >
      <div
        class="v-map-pa-search__magnifying-glass"
        @click="onIconClick"
      />
    </div>
    <div
      v-if="hasResults"
      class="v-map-pa-search__results-container"
    >
      <div class="v-map-pa-search__results">
        <div
          v-for="(result, index) in autocompleteResults"
          :key="index"
          class="v-map-pa-search__result"
          tabindex="0"
        >
          <span v-html="result" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'VMapPASearch',

  model: {
    prop: 'query',
    event: 'search'
  },

  props: {
    type: {
      type: Object,
      required: true,
      validator: type => {
        return type.hasOwnProperty('id') && type.hasOwnProperty('placeholder')
      }
    }
  },

  data() {
    return {
      autocompleteResults: [],
      query: '',
      search: undefined,
      searchClear: undefined
    }
  },

  computed: {
    hasValidQuery() {
      return this.query && this.query.length > 2
    },
    hasResults() {
      return this.autocompleteResults.length > 0
    }
  },

  methods: {
    onInput(e) {
      this.$emit('input', e.target.value)
    },

    onKeyup(e) {
      if (this.searchClear) {
        // if there's a timeout ID, clear it
        clearTimeout(this.searchClear)
      }
      // treat keyboard input keys as literal keys if their length=1 & ignore everything else
      if (e.key.length === 1) {
        this.search = this.search ? this.search + e.key : e.key
        const searchResult = this.computedOptions.slice(1).filter(option =>
          // when the search is length=1, match from the beginning of the labels, else match against whole label
          new RegExp(
            (this.search.length === 1 ? '^' : '') + this.search,
            'i'
          ).test(option.label)
        )[0]

        if (searchResult) {
          if (this.dropdownEnabled) {
            // focus if you have the options in front of you to choose from
            this.$refs.options[
              this.computedOptions.slice(1).indexOf(searchResult)
            ].focus()
          } else {
            // pro-actively select something if you're typing without the options to choose from
            this.select(searchResult.value)
          }
        }
      } else {
        // treat all other keys as clear signals
        this.search = undefined
      }
      // schedule the current search string to be cleared after a set time if subsequent input is not received
      this.searchClear = delay(() => {
        this.search = undefined
      }, 250)
    },

    onEscape() {
      this.resetAutocompleteResults()
    },

    resetAutocompleteResults() {
      this.autocompleteResults = []
    },

    focusInput() {
      this.$refs.input.focus()
    },

    onIconClick() {
      if (this.query) {
        this.submitSearch()
      } else {
        this.focusInput()
      }
    },

    onElementFocus() {
      this.$refs.input.focus()
    },

    onEnter() {
      this.$emit('search', this.query)
      this.submitSearch()
        .then(results => {
          this.autocompleteResults = results
        })
        .catch(e => {
          console.error(e)
          this.autocompleteResults = []
        })
    },

    submitSearch() {
      return new Promise(resolve => {
        // TESTING
        setTimeout(function() {
          resolve([
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
          ])
        }, 500)
      })
      // return axios.post("/search/autocomplete", {
      //   type: this.type.id,
      //   search_term: this.query
      // });
    }
  }
}
</script>