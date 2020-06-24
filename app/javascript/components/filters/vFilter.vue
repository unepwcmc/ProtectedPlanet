<template>
  <div class="filter">
    <h4 
      v-if="title" 
      v-html="title"
    />
    
    <div class="filter__options">
      <checkboxes 
        v-if="type == 'checkbox'"
        :id="id"
        :options="options"
        :pre-selected="preSelected"
        v-on:update:options="updateFilter"
      />

      <radio-buttons 
        v-if="type == 'radio'"
        :id="id"
        :name="name"
        :options="options"
        v-on:update:options="updateFilter"
      />
    </div>

    <checkbox-search
      v-if="type == 'checkbox-search'"
      :id="id"
      :name="name"
      :options="options"
      :pre-selected="preSelectedCheckboxSearch"
      v-on:update:options="updateFilter"
    />
  </div>
</template>

<script>
import Checkboxes from '../form-fields/Checkboxes'
import RadioButtons from '../form-fields/RadioButtons'
import CheckboxSearch from '../form-fields/CheckboxSearch'

export default {
  name: 'v-filter',

  components: { Checkboxes, RadioButtons, CheckboxSearch },

  props: {
    id: {
      required: true,
      type: String
    },
    name: {
      type: String
    },
    options: {
      required: true,
      type: Array // [ { id: String, title: String } ]
    },
    preSelected: {
      type: Array // [ String ]
    },
    resetting: true,
    title: {
      type: String
    },
    type: {
      required: true,
      type: String
    }
  },

  computed: {
    preSelectedCheckboxSearch () {
      return Array.isArray(this.preSelected) && this.preSelected.length ? this.preSelected[0] : null
    }
  },

  created () {
    if(this.preSelected) { this.addPreSelectedToActiveOptions() }
  },

  methods: {
    addPreSelectedToActiveOptions () {
      const preselected = this.preSelectedCheckboxSearch ? this.preSelectedCheckboxSearch : this.preSelected
      
      this.updateFilter(preselected)
    },

    updateFilter(updatedOptions) {
      const data = {
        id: this.id,
        options: updatedOptions
      }

      this.$emit('update:filter', data)
    }
  }
}
</script>