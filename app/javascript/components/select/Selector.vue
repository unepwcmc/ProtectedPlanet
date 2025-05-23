<template>
  <div
    class="selector"
    tabindex="0"
    @focus="showDropdown(!dropdownEnabled)"
  >
    <div
      ref="selected"
      class="selector__selected"
      tabindex="0"
      @click="showDropdown(!dropdownEnabled)"
      @keyup.enter="showDropdown(!dropdownEnabled)"
      @keyup="onKeyup"
    >
      <div class="selector__label">
        {{ selected.label }}
      </div>
      <div
        class="selector__caret"
        :class="{
          'selector__caret--active': dropdownEnabled
        }"
      />
      <div
        v-if="dropdownEnabled"
        class="selector__options"
      >
        <div
          v-for="option in options"
          ref="options"
          :key="option.value"
          :class="{ 'selector__option--active': isSelected(option.value) }"
          class="selector__option"
          tabindex="0"
          @click="select(option.value)"
          @keyup.enter.stop="select(option.value)"
          @keyup.esc.stop="showDropdown(false)"
          @keyup="onKeyup"
          @mouseover="onOptionMouseover"
        >
          {{ option.label }}
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { delay } from 'lodash'
import eventHandler from '../../mixins/mixin-element-event-handler'

export default {
  name: 'Selector',

  mixins: [
    /**
     * Determine if a tab keyup occurred outside of the component.
     * If it did, assume the dropdown is no-longer being used, and hide it.
     * @return void
     */
    eventHandler(document, 'keyup', function (e) {
      if (e.key.toLowerCase() === 'tab') {
        if (!this.$el.contains(document.activeElement)) {
          this.showDropdown(false)
        }
      }
    }),
    /**
     * Determine if a click occurred outside of the component.
     * If it did, assume the dropdown is no-longer being used, and hide it.
     * @return void
     */
    eventHandler(document, 'click', function () {
      if (!this.$el.contains(document.activeElement)) {
        this.showDropdown(false)
      }
    })
  ],

  model: {
    event: 'change',
    prop: 'value'
  },

  props: {
    value: {
      required: true,
      type: String
    },

    options: {
      type: Array,
      required: true,
      validator: options =>
        options.every(
          option =>
            typeof option === 'object' &&
            option.hasOwnProperty('label') &&
            option.hasOwnProperty('value')
        )
    }
  },

  data () {
    return {
      dropdownEnabled: false,
      search: undefined,
      /**
       * Contains a timeout ID used in conjunction with building up a string to match against option labels.
       * As you type, the search term is built up. When you pause, if you delay too long, the search term is reset.
       * @type Number
       */
      searchClear: undefined
    }
  },

  computed: {
    /**
     * The selected value will always resolve to an option. If there is no value,
     * then the selected option is the first in the array.
     * @return Object selected option
     */
    selected () {
      // if a value is present, get the corresponding option or otherwise just get the first one
      if (this.value) {
        return this.options.filter(
          option => option.value === this.value
        )[0]
      }

      return this.options[0]
    }
  },

  methods: {
    onKeyup (e) {
      if (this.searchClear) {
        // if there's a timeout ID, clear it
        clearTimeout(this.searchClear)
      }
      // treat keyboard input keys as literal keys if their length=1 & ignore everything else
      if (e.key.length === 1) {
        this.search = this.search ? this.search + e.key : e.key
        const searchResult = this.options.filter(option =>
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
              this.options.indexOf(searchResult)
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

    onOptionMouseover (e) {
      e.target.focus()
    },

    /**
     * Submit the selected value to the parent component.
     * @param value the value to be submitted from the options.
     * @return void
     */
    select (value) {
      this.$emit('change', value)
      this.showDropdown(false)
    },

    isSelected (value) {
      return this.selected.value === value
    },

    showDropdown (value) {
      if (typeof value === 'boolean') {
        this.dropdownEnabled = value
      } else {
        this.dropdownEnabled = !this.dropdownEnabled
      }
    }
  }
}
</script>