<template>
  <div class="filter">
    <h4 
      v-if="title" 
      v-html="title"
    />

    <checkboxes 
      v-if="type == 'checkbox'"
      :id="id"
      :options="options"
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
</template>

<script>
import Checkboxes from '../form-fields/Checkboxes'
import RadioButtons from '../form-fields/RadioButtons'

export default {
  name: 'v-filter',

  components: { Checkboxes, RadioButtons },

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

      console.log('updateFilter data', data)

      this.$emit('update:filter', data)
    }
  }
}
</script>