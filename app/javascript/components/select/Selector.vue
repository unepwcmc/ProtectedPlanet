<template>
  <div class="selector">
    <div
      ref="selected"
      class="selector__selected"
      tabindex="0"
      @click="showDropdown(true)"
      @focus="showDropdown(true)"
      @keyup.enter="showDropdown(true)"
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
        >
          {{ option.label }}
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { delay, debounce, intersectionBy } from 'lodash'

export default {
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
  data() {
    return {
      dropdownEnabled: false,
      search: undefined,
      searchClear: undefined
    }
  },
  computed: {
    selected() {
      // if a value is present, get the corresponding option or otherwise just get the first one
      if (this.value) {
        return this.options.filter(
          option => option.value === this.value
        )[0]
      }

      return this.options[0]
    }
  },
  created() {
    document.documentElement.addEventListener('click', this.onDocumentClick)
  },
  beforeDestroy() {
    document.documentElement.removeEventListener('click', this.onDocumentClick)
  },
  methods: {
    onDocumentClick(e) {
      e.preventDefault()
      e.stopPropagation()
      if (this.$el.contains(document.activeElement) === false) {
        this.showDropdown(false)
      }
    },
    onKeyup(e) {
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
    select(value) {
      this.$emit('change', value)
      this.showDropdown(false)
    },
    isSelected(value) {
      return this.selected.value === value
    },
    showDropdown(value) {
      if (typeof value === 'boolean') {
        this.dropdownEnabled = value
      } else {
        this.dropdownEnabled = !this.dropdownEnabled
      }
    }
  }
}
</script>