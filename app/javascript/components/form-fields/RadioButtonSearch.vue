<template>
  <div>
    <tabs-fake 
      :children="tabs"
      :pre-selected="preSelectedTabId"
      v-on:click:tab="updateSelectedTab"
    />
    
    <input
      class="margin-space--bottom"
      type="text" 
      v-model="searchTerm"
    />
    
    <div>
      <radio-buttons 
        :id="id"
        :name="name"
        :options="autocomplete"
        :pre-selected="preSelectedRadioId"
        v-on:update:options="updateSelectedRadioId"
      />
    </div>
  </div>
</template>

<script>
import RadioButtons from './RadioButtons.vue'
import TabsFake from '../tabs/TabsFake.vue'

export default {
  name: 'radio-buttons-search',

  components: { RadioButtons, TabsFake },

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
      validator: o => o === null || (o.hasOwnProperty('id') && typeof o.id === 'string'
        && o.hasOwnProperty('type') && typeof o.type === 'string')
    },
    name: { 
      type: String,
      required: true 
    }
  },

  data () {
    return {
      preSelectedRadioId: '',
      preSelectedTabId: '',
      selectedTabId: '',
      searchTerm: ''
    }
  },

  created () {
    if(this.hasPreSelectedOptions) { this.handlePreSelectedOptions() }

    this.$eventHub.$on('reset:filter-options', this.reset)
  },

  computed: {
    autocomplete () {
      let autocompleteOptions = this.options
        .filter(option => option.id == this.selectedTabId)
        .map(option => option.autocomplete)
        [0]

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
      this.preSelectedRadioId = this.preSelected.id
    },

    reset () {
      this.preSelectedRadioId = ''
      this.hasPreSelectedTabId = ''
      this.selectedTabId = ''
      this.searchTerm = ''
    },

    updateSelectedTab (id) {
      this.reset()
      this.selectedTabId = id
    },

    updateSelectedRadioId (selectedRadioId) {
      const updatedOptions = {
        type: this.selectedTabId,
        id: selectedRadioId
      }

      this.$emit('update:options', updatedOptions)
    }
  }
}
</script>
