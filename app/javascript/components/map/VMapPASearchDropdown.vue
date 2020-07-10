<template>
  <div class="v-map-pa-search__dropdown">
    {{ label }}
    <selector v-bind="{ options, state }" @change="$emit('change', $event)" />
  </div>
</template>
<script>
import Selector from "../select/Selector";

export default {
  name: "VMapPASearchDropdown",

  components: {
    Selector
  },

  model: {
    event: "change",
    prop: "state"
  },

  props: {
    state: {
      required: true
    },
    label: {
      type: String,
      required: true
    },
    options: {
      type: Array,
      required: true,
      validator: options =>
        options.every(
          option =>
            option.hasOwnProperty("label") && option.hasOwnProperty("value")
        )
    }
  }
};
</script>