<template>
  <div
    class="select--searchable-filterable relative"
    :class="{'select--disabled': isDisabled}"
  >
    <input
      :id="config.id"
      v-model="selectedInternal.name"
      type="hidden"
      :name="config.id"
    >

    <div :class="['select__search relative', {'select__search--active': isActive}]">
      <label
        v-if="config.label"
        class="screen-reader"
        :for="searchId"
      >{{ config.label }} search</label>
      <input
        :id="searchId"
        v-model="searchTerm"
        class="select__search-input"
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

      <span class="select__search-icons">
        <button
          v-show="!showResetIcon && !hasSelectedOption"
          class="select__search-icon"
        />
        <button 
          v-show="showResetIcon"
          :id="searchResetId"
          class="select__search-icon select__search-icon--delete"
          @click="resetSearchTerm"
        />
        <button 
          v-show="hasSelectedOption"
          class="select__search-icon--reset"
          @click="resetSelect"
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
      class="select__dropdown"
    >
      <li
        v-for="(option, index) in filteredOptions"
        v-show="matchesSearchTerm(option)"
        :id="getOptionInputId(option)"
        :key="option.id"
        :class="['select__option hover--pointer', conditionalOptionClasses(option, index)]"
        role="option"
        :aria-selected="isHighlighted(index).toString()"
        @click="selectOption(option)"
      >
        {{ option.name }}
      </li>
    </ul>

    <div class="select__categories">
      <div 
        class="select__category-label"
        @click="toggleCategories"
      >
        {{ selectedCategoryName }}
      </div>

      <ul :class="['select__category-wrapper', {'active': categoriesActive}]">
        <li 
          v-for="category, index in categories"
          class="select__category"
          @click="updateCategory(index)"
        >
          {{ category.name }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import mixinPopupCloseListeners from '../../mixins/mixin-popup-close-listeners'
import mixinSelectShared from '../../mixins/mixin-select-shared'
import VSelectSearchable from './VSelectSearchable'
const UNDEFINED_ID = '__UNDEFINED__'
const UNDEFINED_OBJECT = { id: UNDEFINED_ID, name: 'None' }

export default {
  name: 'VSelectSearchableFilterable',

  components: { VSelectSearchable },

  mixins: [
    mixinPopupCloseListeners({closeCallback: 'closeSelect'}),
    mixinSelectShared
  ],

  props: {
    config: {
      required: true,
      type: Object // { id: String, label: String, placeholder: String }
    },
    categories: {
      default: () => [],
      type: Array // [ { name: String, options: [ { id: Number, name: String } ] } ]
    },
    selected: {
      type: Object, // { id: String, name: String }
      default: () => UNDEFINED_OBJECT
    }
  },

  data () {
    return {
      selectedInternal: null,
      categoryIndex: 0,
      categoriesActive: false
    }
  },

  computed: {
    filteredOptions () {
      return this.options.filter(option => this.matchesSearchTerm(option))
    },
    hasSelectedOption () {
      return this.selectedInternal !== UNDEFINED_OBJECT
    },
    defaultSearchTerm () {
      return this.placeholder ? this.placeholder : 'Select'
    },
    selectedCategoryName () {
      return this.categories[this.categoryIndex].name
    },
    options () {
      return this.categories[this.categoryIndex].options
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
      this.$eventHub.$emit('update:selectedInternal', newSelectedInternal)
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
      this.highlightedOptionIndex = 0
    },

    updateCategory (index) {
      this.categoryIndex = index
    },

    toggleCategories () {
      this.categoriesActive = !this.categoriesActive
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
      
      // this.$ga.event('SELECT - Select Country/Region', 'click', option.name)
    },

    setSearchTermToSelected () {
      this.searchTerm = this.selectedInternal.name === 'None' ? this.defaultSearchTerm : this.selectedInternal.name
    },

    conditionalOptionClasses (option, index) {
      return {
        'select__option--selected': this.isSelected(option),
        'select__option--highlighted': this.isHighlighted(index)
      }
    },

    resetSelect () {
      this.searchTerm = ''
      this.selectedInternal = UNDEFINED_OBJECT
    }
  }
}
</script>