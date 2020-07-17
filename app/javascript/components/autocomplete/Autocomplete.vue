<template>
  <div class="autocomplete__container">
    <div
      class="autocomplete"
      @focus="focusInput"
    >
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
      >
      <div
        class="autocomplete__magnifying-glass"
        @click="onMagnifyingGlassClick"
      />
    </div>
    <div
      v-show="hasResults"
      class="autocomplete__results-container"
    >
      <div class="autocomplete__results">
        <div
          v-for="(result, index) in results"
          ref="results"
          :key="index"
          class="autocomplete__result"
          tabindex="0"
          @click="submit(result)"
          @keyup.enter.stop.prevent="submit(result)"
          @mouseover="onResultMouseover"
        >
          {{ result }}
        </div>
      </div>
    </div>
    <div tabindex="0" />
  </div>
</template>

<script>
import { debounce } from 'lodash'
import eventHandler from '../../mixins/mixin-element-event-handler'

export default {
  name: 'Autocomplete',

  mixins: [
    /**
     * Determine if a tab keyup occurred outside of the component.
     * If it did, reset the component.
     * @return void
     */
    eventHandler(document, 'keyup', function (e) {
      if (e.key.toLowerCase() === 'tab') {
        if (!this.$el.contains(document.activeElement)) {
          this.reset()
        }
      }
    }),
    /**
     * Determine if a click occurred outside of the component.
     * If it did, reset the component.
     * @return void
     */
    eventHandler(document, 'click', function () {
      if (this.$el.contains(document.activeElement) === false) {
        this.reset()
      }
    })
  ],

  props: {
    /**
     * The autocomplete depends on a callback to fetch its results.
     * The callback should be a function with a parameter for the search term.
     * It should return a Promise that resolves to an array of strings.
     */
    autocompleteCallback: {
      type: Function,
      required: true
    },
    /**
     * The placeholder to be seen before any input has been entered.
     */
    placeholder: {
      default: '...',
      type: String,
      required: false
    },

    resetEventName: {
      default: 'autocompleteReset',
      type: String
    }
  },

  data () {
    return {
      /**
       * Determine whether to prevent an autocomplete.
       * @type Boolean
       */
      busy: false,
      /**
       * Autocomplete results.
       * @type Array
       */
      results: [],
      /**
       * The search term. Replaced by an autocomplete result when selected.
       * @type String
       */
      search: '',
    }
  },

  computed: {
    hasResults () {
      return this.results.length > 0
    }
  },

  methods: {
    onEscape () {
      this.reset()
    },

    /**
     * When [enter] is triggered by the input, focus on the first result 
     * so it can be used on the next trigger if there are any.
     * If there are no results then submit the search.
     * @return void
     */
    onEnter () {
      if (this.search) {
        if (this.hasResults) {
          this.$refs.results[0].focus()
        } else {
          this.submit()
        }
      }
    },

    /**
     * When the search icon is clicked, search if there's a term and there
     * aren't autocomplete results. Otherwise focus the input.
     * Focus the first result if they are available.
     * @return void
     */
    onMagnifyingGlassClick () {
      if (this.search) {
        if (this.hasResults) {
          this.$refs.results[0].focus()
        } else {
          this.submit()
        }
      } else {
        this.focusInput()
      }
    },

    onInput (e) {
      this.updateSearch(e.target.value)
      if (!this.busy) {
        this.autocomplete()
      }
    },

    reset () {
      this.busy = true
      this.resetAutocompleteResults()
      this.updateSearch('')
      this.busy = false
    },

    onResultMouseover (e) {
      e.target.focus()
    },

    resetAutocompleteResults () {
      this.results = []
    },

    focusInput () {
      this.$refs.input.focus()
    },

    updateSearch (value) {
      this.search = value
    },

    /**
     * The autocomplete is a debounced function.
     * @see https://lodash.com/docs/4.17.15#debounce
     * If in a [busy] state, do not run the autocomplete.
     * Otherwise, run the [autocompleteCallback] function and expect it
     * to return a Promise that resolves to an array of [result] strings.
     * @return void
     */
    autocomplete: debounce(function () {
      if (this.busy) {
        return
      }
      this.busy = true
      this.autocompleteCallback(this.search).then(results => {
        this.results = results
        setTimeout(() => this.focusInput(), 0)
      }).catch(e => {
        console.error({e})
        this.resetAutocompleteResults()
      }).finally(() => this.busy = false)
    }, 250),

    /**
     * When used, this will submit the present [search] term.
     * If supplied with the [search] argument, it will be used in place of it.
     * Autocomplete results are cleared when a submit occurs and the search
     * term will be emitted from the component to be used by the parent.
     * @param search an overriding search term to be used if present
     * @return void
     */
    submit (search) {
      this.busy = true
      if (search) {
        this.updateSearch(search)
      }
      this.resetAutocompleteResults()
      this.$emit('submit', this.search)
      this.busy = false
    }
  }
}
</script>