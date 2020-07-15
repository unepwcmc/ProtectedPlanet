<template>
  <div class="autocomplete__container">
    <div class="autocomplete" @focus="focusInput">
      <input
        ref="input"
        class="autocomplete__input"
        type="text"
        :disabled="busy"
        :placeholder="placeholder"
        :value="search"
        @input="onInput"
        @keyup.enter.prevent.stop="onEnter"
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
          @click="submit(result)"
          @keyup.enter.stop.prevent="submit(result)"
        >{{ result }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import { debounce } from 'lodash'

export default {
  name: 'Autocomplete',

  data() {
    return {
      busy: false,
      results: [],
      search: '',
    }
  },

  props: {
    autocompleteCallback: {
      type: Function,
      required: true
    },
    placeholder: String,
  },

  computed: {
    hasResults() {
      return this.results.length > 0
    }
  },

  methods: {
    onEscape() {
      this.resetAutocompleteResults()
    },

    onEnter() {
      if (!this.hasResults) {
        this.submit()
      }
    },

    onIconClick() {
      if (this.search) {
        this.submit()
      } else {
        this.focusInput()
      }
    },

    onInput(e) {
      console.log(e.target.value)
      this.updateSearch(e.target.value)
      if (!this.busy) {
        this.autocomplete()
      }
    },

    resetAutocompleteResults() {
      this.results = []
    },

    focusInput() {
      this.$refs.input.focus()
    },

    updateSearch(value) {
      this.search = value
    },

    delayUnbusy(delay = 3000) {
      setTimeout(() => this.busy = false, delay)
    },

    autocomplete: debounce(function () {
      if (this.busy) {
        return
      }
      this.busy = true
      this.autocompleteCallback(this.search).then(results => {
        this.results = results
      }).finally(() => this.delayUnbusy())
    }, 3000),

    submit(search) {
      this.busy = true
      if (search) {
        this.updateSearch(search)
      }
      this.resetAutocompleteResults()
      this.$emit('submit', this.search)
      this.delayUnbusy()
    }
  }
}
</script>