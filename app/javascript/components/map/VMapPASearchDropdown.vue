<template>
  <div class="v-map-pa-search__dropdown">
    {{ label }}
    <selector
      v-bind="{ options, value }"
      @change="$emit('change', $event)"
    />
  </div>
</template>
<script>
import Selector from '../select/Selector'

export default {
  name: 'VMapPASearchDropdown',

  components: {
    Selector
  },

  model: {
    event: 'change',
    prop: 'value'
  },

  props: [
    'label',
    'options',
    'value',
  ]
}
</script>