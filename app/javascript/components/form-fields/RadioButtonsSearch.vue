<template>
  <div>
    <tabs-fake 
      :children="tabs"
      v-on:click:tab="updateSelectedOption"
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
        v-on:update:options="updateSelectedAutocompleteOption"
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
    name: { 
      type: String,
      required: true 
    }
  },

  data () {
    return {
      searchTerm: '',
      selectedOptionId: ''
    }
  },

  created () {
    this.$eventHub.$on('reset:filter-options', this.reset)
  },

  mounted () {
    this.reset()
  },

  computed: {
    autocomplete () {
      let autocompleteOptions = this.options
        .filter(option => option.id == this.selectedOptionId)
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
    reset () {
      this.searchTerm = ''
      this.selectedOptionId = ''
    },

    updateSelectedOption (id) {
      this.selectedOptionId = id
    },

    updateSelectedAutocompleteOption (selectedRadioId) {
      const updatedOptions = {
        type: this.selectedOptionId,
        id: selectedRadioId
      }

      this.$emit('update:options', updatedOptions)
    }
  }
}
</script>
