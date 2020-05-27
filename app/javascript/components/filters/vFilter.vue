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

      <radio-buttons-search
        v-if="type == 'radio-search'"
        :id="id"
        :name="name"
        :options="options"
        v-on:update:options="updateFilter"
      />
    </div>
  </div>
</template>

<script>
import Checkboxes from '../form-fields/Checkboxes'
import RadioButtons from '../form-fields/RadioButtons'
import RadioButtonsSearch from '../form-fields/RadioButtonsSearch'

export default {
  name: 'v-filter',

  components: { Checkboxes, RadioButtons, RadioButtonsSearch },

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
      type: String
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

  methods: {
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