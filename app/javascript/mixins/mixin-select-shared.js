import { isTabForward, isTabBackward } from '../helpers/focus-helpers'
import { KEYCODES } from '../helpers/keyboard-helpers'

const DEFAULT_SELECT_MESSAGE = 'Select option'

export default {
  data () {
    return {
      isActive: false,
      highlightedOptionIndex: -1,
      searchTerm: '',
      dropdownId: 'v-select-dropdown-' + this.config.id,
      dropdownOptionsName: 'v-select-dropdown-input' + this.config.id,
      toggleId: 'v-select-toggle-' + this.config.id,
      searchId: 'v-select-search-' + this.config.id,
      searchResetId: 'v-select-search-reset-' + this.config.id
    }
  },

  computed: {
    hasKeyboardFocus () {
      return this.highlightedOptionIndex >= 0
    },

    highlightedOptionId () {
      if (this.isActive && this.filteredOptions.length && this.hasKeyboardFocus) {
        return this.getOptionInputId(this.filteredOptions[this.highlightedOptionIndex])
      }

      return null
    },

    isDisabled () {
      return !this.options.length
    },

    placeholder () {
      return DEFAULT_SELECT_MESSAGE
    },

    showOptions () {
      return this.isActive && Boolean(this.filteredOptions.length)
    },

    showResetIcon () {
      return this.searchTerm && this.isActive
    },
  },

  methods: {
    toggleSelect (e) {
      if (this.options.length && !this.isActive) {
        this.openSelect(e)
      } else {
        this.closeSelect(e)
      }
    },

    isHighlighted (index) {
      return index === this.highlightedOptionIndex
    },

    resetHighlightedIndex() {
      this.highlightedOptionIndex = -1
    },

    getOptionInputId (option) {
      return `option-${this.config.id}-${option.id}`
    },

    matchesSearchTerm (option) {
      const regex = new RegExp(`${this.searchTerm}`, 'i')
      const match = option.name.match(regex)

      return !this.searchTerm || match
    },

    resetSearchTerm () {
      this.$el.querySelector('#' + this.searchId).focus()
      this.searchTerm = ''
    },

    addTabFromSearchListener () {
      this.$el.querySelector('#' + this.searchId).addEventListener('keydown', e => {
        if (isTabBackward(e)) {
          this.closeSelect()
        } else if (isTabForward(e) && !this.showResetIcon) {
          this.closeSelect()
        }
      })
    },

    addTabForwardFromResetListener () {
      this.$el.querySelector('#' + this.searchResetId).addEventListener('keydown', e => {
        if (isTabForward(e)) {
          this.closeSelect()
        }
      })
    },

    addArrowKeyListeners () {
      this.$el.querySelector('#' + this.searchId).addEventListener('keydown', e => {
        switch (e.keyCode) {
        case KEYCODES.down:
          this.incremementKeyboardFocus()
          break
        case KEYCODES.up:
          this.decrementKeyboardFocus()
          break
        case KEYCODES.enter:
          this.updateSelectedOption()
          break
        case KEYCODES.esc:
          document.activeElement.blur()
          break
        }
      })
    },

    incremementKeyboardFocus () {
      if (this.highlightedOptionIndex === this.filteredOptions.length - 1) {
        this.highlightedOptionIndex = 0
      } else {
        this.highlightedOptionIndex++
      }
    },

    decrementKeyboardFocus () {
      if (this.highlightedOptionIndex === 0) {
        this.highlightedOptionIndex = this.filteredOptions.length - 1
      } else if (this.hasKeyboardFocus) {
        this.highlightedOptionIndex--
      }
    },

    updateSelectedOption () {
      if(this.filteredOptions.length) { 
        if(this.hasKeyboardFocus) {
          this.selectOption(this.filteredOptions[this.highlightedOptionIndex])
        } else {
          this.selectOption(this.filteredOptions[0])
        }
      }
    }
  },
}
