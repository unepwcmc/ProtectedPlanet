<template>
  <div>
    <tabs-fake 
      :children="tabs"
      v-on:click:tab="updateSelectedOption"
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
      console.log('autocomplete', this.options)
      console.log('autocomplete', this.selectedOptionId)
      return this.options
        .filter(option => option.id == this.selectedOptionId)
        .map(option => option.autocomplete)
        [0]
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
      this.selectedOptionId = this.options[0].id
    },

    updateSelectedOption (id) {
      this.selectedOptionId = id
    },

    updateSelectedAutocompleteOption (selectedRadioId) {
      const updatedOptions = {
        type: this.selectedOptionId,
        id: selectedRadioId
      }

      this.$emit('update:options', data)
    }
  }
}
</script>
