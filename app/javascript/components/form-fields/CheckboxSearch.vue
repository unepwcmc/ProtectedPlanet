<template>
  <div>
    <tabs-fake 
      :children="tabs"
      class="tabs--rounded-small"
      :pre-selected-id="selectedTabId"
      v-on:click:tab="updateSelectedTab"
    />
    
    <input
      class="input--search margin-space--bottom"
      type="text" 
      v-model="searchTerm"
    />
    
    <div class="filter__options">
      <checkboxes 
        :clear-index="clearIndex"
        :id="id"
        :options="autocomplete"
        :pre-selected="preSelectedCheckboxes"
        ref="checkboxes"
        v-on:update:options="updateSelectedCheckboxes"
      />
    </div>
  </div>
</template>

<script>
import Checkboxes from './Checkboxes.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'checkbox-search',

  components: { Checkboxes, TabsFake },

  props: {
    clearIndex: {
      type: Number
    },
    id: { 
      type: String,
      required: true 
    },
    options: { 
      type: Array, // { id: String, title: String, autocomplete: [ id: String, title: String ] }
      required: true 
    },
    preSelected: {
      type: Object, // { type: String, options: Array },
      // validator: o => o === null || (o.hasOwnProperty('options') && typeof o.options === 'array'
      //   && o.hasOwnProperty('type') && typeof o.type === 'string')
    },
    name: { 
      type: String,
      required: true 
    }
  },

  data () {
    return {
      defaultTabId: this.options[0].id,
      preSelectedCheckboxes: null,
      selectedTabId: '',
      searchTerm: ''
    }
  },

  created () {
    this.handlePreSelectedOptions()    
  },

  mounted () {
    this.$eventHub.$on('reset:filter-options', this.reset)

    this.defaultTabId = this.options[0].id
  },
  
  watch: {
    clearIndex () {
      this.reset
    }
  },

  computed: {
    autocomplete () {
      let autocompleteOptions = this.options
        .filter(option => option.id == this.selectedTabId)
        .map(option => option.autocomplete)
        [0]

      if(!autocompleteOptions) {
        autocompleteOptions = [] 
      }

      if(this.searchTerm !== '') {
        const regex = new RegExp(`${this.searchTerm}`, 'i')
        
        autocompleteOptions = autocompleteOptions.filter(option => {
          return option.title.match(regex)
        })
      }
      
      return autocompleteOptions
    },

    tabs () {
      return this.options.map(option => {
        return {
          id: option.id,
          title: option.title
        }
      })
    }
  },

  methods: {
    handlePreSelectedOptions () {
      if (this.preSelected) {
        this.selectedTabId = this.preSelected.type
        this.preSelectedCheckboxes = this.preSelected.options
      } else {
        this.selectedTabId = this.defaultTabId
      } 
    },

    reset () {
      this.preSelectedCheckboxes = null
      this.selectedTabId = this.defaultTabId
      this.searchTerm = ''
    },

    updateSelectedTab (id) {
      this.reset()
      this.selectedTabId = id
      if(this.$refs.checkboxes) { this.$refs.checkboxes.reset() }

    },

    updateSelectedCheckboxes (selectedCheckboxArray) {
      const updatedOptions = {
        type: this.selectedTabId,
        options: selectedCheckboxArray
      }

      this.$emit('update:options', updatedOptions)
    }
  }
}
</script>
