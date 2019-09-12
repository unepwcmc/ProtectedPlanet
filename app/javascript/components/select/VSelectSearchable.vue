<template>
  <div
    class="v-select v-select--search relative"
    :class="{'v-select--disabled': isDisabled}"
  >
    <input
      :id="config.id"
      v-model="selectedInternal.name"
      type="hidden"
      :name="config.id"
    >

    <div
      v-if="config.label"
      class="v-select__label"
    >
      <label
        :for="toggleId"
        class="v-select__selection"
      >{{ config.label }}</label>
      <slot name="label-icon" />
    </div>

    <div :class="['v-select__search relative', {'v-select__search--active': isActive}]">
      <label
        v-if="config.label"
        class="screen-reader"
        :for="searchId"
      >{{ config.label }} search</label>
      <input
        :id="searchId"
        v-model="searchTerm"
        class="v-select__search-input"
        type="text"
        role="combobox"
        aria-haspopup="listbox"
        aria-autocomplete="list"
        :aria-expanded="showOptions.toString()"
        :aria-owns="dropdownId"
        :aria-activedescendant="highlightedOptionId" 
        :placeholder="config.placeholder"
        :disabled="isDisabled"
        @focus="openSelect"
      >

      <span class="v-select__search-icons">
        <button
          v-show="!showResetIcon"
          class="v-select__search-icon"
        />
        <button 
          v-show="showResetIcon"
          :id="searchResetId"
          class="v-select__search-icon v-select__search-icon--reset hover--pointer"
          @click="resetSearchTerm"
        />
        <span 
          class="drop-arrow drop-arrow--margin-right arrow-svg hover--pointer"
          @click="toggleSelect"
        />
      </span>
    </div>

    <ul 
      v-show="showOptions" 
      :id="dropdownId" 
      role="listbox" 
      class="v-select__dropdown"
    >
      <li
        v-for="(option, index) in filteredOptions"
        v-show="matchesSearchTerm(option)"
        :id="getOptionInputId(option)"
        :key="option.id"
        :class="['v-select__option hover--pointer', conditionalOptionClasses(option, index)]"
        role="option"
        :aria-selected="isHighlighted(index).toString()"
        @click="selectOption(option)"
      >
        {{ option.name }}
      </li>
    </ul>
  </div>
</template>

<script>
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'
import mixinSelectShared from '../../mixins/mixin-select-shared'
import { eventHub } from '../../vue.js'
const UNDEFINED_ID = '__UNDEFINED__'
const UNDEFINED_OBJECT = { id: UNDEFINED_ID, name: 'None' }

export default {
  name: 'VSelectSearch',

  mixins: [
    mixinPopupCloseListeners({closeCallback: 'closeSelect'}),
    mixinSelectShared
  ],

  props: {
    config: {
      required: true,
      type: Object // { id: String, label: String, placeholder: String }
    },
    options: {
      default: () => [],
      type: Array // [ { } ]
    },
    selected: {
      type: Object,
      default: () => UNDEFINED_OBJECT
    }
  },

  data () {
    return {
      selectedInternal: null,
    }
  },

  computed: {
    filteredOptions () {
      return this.options.filter(option => this.matchesSearchTerm(option))
    }
  },

  watch: {
    searchTerm () {
      this.resetHighlightedIndex()
    },

    selected (newSelectedOption) {
      this.selectedInternal = newSelectedOption === null ?
        UNDEFINED_OBJECT :
        newSelectedOption
      this.setSearchTermToSelected()
    },

    selectedInternal (newSelectedInternal) {
      this.$store.dispatch('table/updateSearchTerm', newSelectedInternal)
      eventHub.$emit('update:selectedInternal')
    }
  },

  created () {
    this.initializeSelectedInternal()
  },

  mounted () {
    this.addTabFromSearchListener()
    this.addArrowKeyListeners()
    this.addTabForwardFromResetListener()
  },

  methods: {
    closeSelect () {
      this.setSearchTermToSelected()
      this.resetHighlightedIndex()
      this.isActive = false
    },

    openSelect () {
      this.searchTerm = ''
      this.isActive = true
    },

    initializeSelectedInternal () {
      if (this.selected === null) {
        this.selectedInternal = UNDEFINED_OBJECT
      } else {
        this.selectedInternal = this.selected
        this.setSearchTermToSelected()
      }
    },

    isSelected (option) {
      return option.id === this.selectedInternal.id
    },

    selectOption (option) {
      this.selectedInternal = option
      this.closeSelect()
      document.activeElement.blur()
    },

    setSearchTermToSelected () {
      this.searchTerm = this.selectedInternal.name
    },

    conditionalOptionClasses (option, index) {
      return {
        'v-select__option--selected': this.isSelected(option),
        'v-select__option--highlighted': this.isHighlighted(index)
      }
    }
  }
}
</script>