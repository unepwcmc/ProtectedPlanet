<template>
  <div class="autocomplete__container">
    <div class="autocomplete" @focus="focusInput">
      <input
        ref="input"
        class="autocomplete__input"
        type="text"
        :disabled="busy"
        :placeholder="placeholder"
        v-model="search"
        @input="onInput"
        @keyup.esc.prevent.stop="onEscape"
      />
      <div class="autocomplete__magnifying-glass" @click="onIconClick" />
    </div>
    <div v-if="hasResults" class="autocomplete__results-container">
      <div class="autocomplete__results">
        <div
          v-for="(result, index) in results"
          ref="results"
          :key="index"
          class="autocomplete__result"
          tabindex="0"
          @click="selectResult(result)"
          @keyup.enter.stop.prevent="selectResult(result)"
        >{{ result }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import { debounce } from 'lodash'

export default {
  name: 'Autocomplete',

  model: {
    prop: 'results',
    event: 'change'
  },

  data() {
    return {
      search: '',
      busy: false
    }
  },

  props: {
    placeholder: String,
    results: {
      type: Array,
      default: []
    }
  },

  computed: {
    hasResults() {
      return this.results.length > 0
    }
  },

  methods: {
    runSearch: debounce(function () {
      this.$emit('search', this.search)
    }, 1000),

    onEscape() {
      this.resetAutocompleteResults()
    },

    onIconClick() {
      if (!this.search) {
        this.focusInput()
      } else {
        this.$emit('search', this.search)
      }
    },

    onInput() {
      if (!this.busy) {
        this.runSearch()
      }
    },

    resetAutocompleteResults() {
      this.$emit('change', [])
    },

    focusInput() {
      this.$refs.input.focus()
    },

    selectResult(result) {
      this.busy = true
      this.search = result
      this.$emit('search', this.search)
      this.resetAutocompleteResults()
      setTimeout(() => {
        this.busy = false
      }, 3000)
    },
  }
}
</script>