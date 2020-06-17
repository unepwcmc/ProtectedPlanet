<template>
  <div>
    <tabs-fake 
      :children="tabs"
      class="tabs--rounded-small"
      :pre-selected="preSelectedTabId"
      v-on:click:tab="updateSelectedTab"
    />
    
    <input
      class="input--search margin-space--bottom"
      type="text" 
      v-model="searchTerm"
    />
    
    <div class="filter__options">
      <checkboxes 
        :id="id"
        :options="autocomplete"
        :pre-selected="preSelected"
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
    id: { 
      type: String,
      required: true 
    },
    options: { 
      type: Array, // { id: String, title: String, autocomplete: [ id: String, title: String ] }
      required: true 
    },
    preSelected: {
      type: Object, // { id: String, type: String },
      // validator: o => o === null || (o.hasOwnProperty('id') && typeof o.id === 'string'
      //   && o.hasOwnProperty('type') && typeof o.type === 'string')
    },
    name: { 
      type: String,
      required: true 
    }
  },

  data () {
    return {
      preSelectedCheckboxes: '',
      preSelectedTabId: '',
      selectedTabId: '',
      searchTerm: ''
    }
  },

  created () {
    if(this.hasPreSelectedOptions) { this.handlePreSelectedOptions() 
    }

    this.$eventHub.$on('reset:filter-options', this.reset)
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

    hasPreSelectedOptions () {
      return typeof this.preSelected === 'object'
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
      if (this.preSelected === null) return
      this.hasPreSelectedTabId = this.preSelected.type
      this.preSelectedCheckboxes = this.preSelected.options
    },

    reset () {
      this.preSelectedCheckboxes = ''
      this.hasPreSelectedTabId = ''
      this.selectedTabId = ''
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
