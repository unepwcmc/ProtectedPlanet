<template>
  <div class="filter">
    <h4 
      v-if="title" 
      v-html="title"
    />

    <checkboxes 
      v-if="type == 'checkbox'"
      :id="id"
      :name="name"
      :options="options"
    />

    <radio-buttons 
      v-if="type == 'radio'"
      :id="id"
      :name="name"
      :options="options"
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
      required: true,
      type: String
    },
    options: {
      required: true,
      type: Array // [ { id: String, title: String } ]
    },
    title: {
      type: String
    },
    type: {
      required: true,
      type: String
    }
  }
}
</script>