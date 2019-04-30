<template>
  <div class="v-select relative" :class="{'v-select--disabled': isDisabled}">
    <input type="hidden" :name="config.id" :id="config.id" v-model="selectedInternal.name" />

    <div v-if="config.label" class="v-select__label">
      <label :for="toggleId" class="v-select__selection">{{ config.label }}</label>
      <slot name="label-icon"></slot>
    </div>

    <div :class="['v-select__search relative', {'v-select__search--active': isActive}]">
      <input
        id="v-select-search"
        :class="['v-select__search-input', hasSelectedClass]"
        type="text" 
        v-model="searchTerm" 
        :placeholder="selectionMessage"
        aria-haspopup="true"
        :aria-controls="dropdownId"
        :disabled="isDisabled"
        @focus="openSelect">
      <span class="v-select__search-icons">
        <span class="v-select__search-icon" v-show="!showResetIcon"></span>
        <button id="v-select-search-reset" class="v-select__search-icon v-select__search-icon--reset hover--pointer" v-show="showResetIcon" @click="resetSearchTerm"></button>
        <span @click="toggleSelect" class="drop-arrow arrow-svg hover--pointer"></span>
      </span>
    </div>

    <ul 
      v-show="isActive" 
      :id="dropdownId" 
      role="radiogroup" 
      class="v-select__dropdown ul--unstyled">

      <li
        class="v-select__option"
        v-for="option in options"
        :key="option.id"
        v-show="matchesSearchTerm(option)">
        <label class="v-select__option-label" :for="getOptionInputId(option)">
          <input
            class="v-select__default-radio"
            type="radio"
            :id="getOptionInputId(option)"
            :name="dropdownOptionsName"
            :value="option"
            v-model="selectedInternal">
          <span @click="closeSelect" class="v-select__option-text">{{ option.name }}</span>
        </label>
      </li>

    </ul> 

  </div>
</template>

<script>
var UNDEFINED_ID = '__UNDEFINED__';
var UNDEFINED_OBJECT = { id: UNDEFINED_ID, name: 'None' }
var DEFAULT_SELECT_MESSAGE = 'Search releases...'

module.exports = {
  name: 'v-select-searchable',
  
  mixins: [
    mixinPopupCloseListeners('closeSelect')
  ],

  props: {
    config: {
      required: true,
      type: Object
    },
    options: {
      default: function () { return [] },
      type: Array
    },
    selected: {
      default: null,
    }
  },

  data: function () {
    return {
      isActive: false,
      selectedInternal: null,
      searchTerm: '',
      dropdownId: 'v-select-dropdown-' + this.config.id,
      dropdownOptionsName: 'v-select-dropdown-input' + this.config.id,
      toggleId: 'v-select-toggle-' + this.config.id
    }
  },

  computed: {
    isDisabled: function () {
      return !this.options.length
    },

    selectionMessage: function () {
      return this.selectedInternal.id === UNDEFINED_ID ? DEFAULT_SELECT_MESSAGE : this.selectedInternal.name
    },

    showResetIcon: function () {
      return this.searchTerm && this.isActive
    },

    hasSelectedClass: function () {
      return {
        'v-select__search-input--has-selected': this.selectedInternal.id !== UNDEFINED_ID
      }
    }
  },

  watch: {
    selected: function (newSelectedOption) {
      this.selectedInternal = newSelectedOption
    },

    selectedInternal: function (newSelectedInternal) {
      this.$emit('update:selected-option', newSelectedInternal)
    },

    options: function () {
      this.addTabListenerToRadios()
    }
  },

  created: function () {
    this.initializeSelectedInternal()
  },

  mounted: function () {
    this.addTabBackFromSearchListener()
    this.addTabListenerToRadios()
    this.addTabIntoRadioGroupListener()
  },

  methods: {
    closeSelect: function () {
      this.searchTerm = ''
      this.isActive = false
    },

    openSelect: function () {
      this.isActive = true
    },

    toggleSelect: function (e) {
      if (this.options.length && !this.isActive) {
        this.openSelect(e)
      } else {
        this.closeSelect(e)
      }
    },

    initializeSelectedInternal: function () {
      if (this.selected === null) {
        this.selectedInternal = UNDEFINED_OBJECT
      } else {
        this.selectedInternal = this.selected
      }
    },

    isSelected: function (option) {
      return option.id === this.selectedInternal.id
    },

    getOptionInputId: function (option) {
      return 'option-' + this.config.id + '-' + option.id
    },

    matchesSearchTerm: function (option) {
      var regex = new RegExp(this.searchTerm, 'i')
      var match = option.name.match(regex)

      return !Boolean(this.searchTerm) || match
    },

    resetSearchTerm: function () {
      this.$el.querySelector('#v-select-search').focus()
      this.searchTerm = ''
    },

    addTabListenerToRadios: function () {
      Array.prototype.forEach.call(this.$el.querySelectorAll('.v-select__default-radio'), function (input) {
        input.addEventListener('keydown', function (e) {
          if (isTabForward(e)) {
            this.closeSelect()
          }
        }.bind(this))
      }.bind(this))
    },

    addTabIntoRadioGroupListener: function () {
      this.$el.querySelector('#v-select-search-reset').addEventListener('keydown', function (e) {
        if (isTabForward(e)) {
          e.preventDefault()

          var optionEls = this.$el.querySelectorAll('.v-select__option')
          var radioToFocus = getRadioToFocus(optionEls)

          if (radioToFocus) {
            radioToFocus.focus()
          } else {
            this.closeSelect()
            document.activeElement.blur()
          }
        }
      }.bind(this))
    },
    
    addTabBackFromSearchListener: function () {
      this.$el.querySelector('#v-select-search').addEventListener('keydown', function (e) {
        if (isTabBackward(e)) {
          this.closeSelect()
        }
      }.bind(this))
    }
  }
}
</script>