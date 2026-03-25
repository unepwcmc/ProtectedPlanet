<template>
  <th class="table-head__cell">
    <span class="table-head__title">{{ filter.title }}</span>

    <tooltip 
      v-if="hasTooltip" 
      :text="filter.tooltip" />

    <div 
      v-if="hasOptions" 
      class="table__sorting" 
      @click="sort()"
    >
      <span 
        alt="Sort results" 
        class="table__sort table__sort--ascending" 
      />
      <span 
        alt="Sort results" 
        class="table__sort table__sort--descending" 
      />
    </div>
  </th>
</template>

<script>
import { eventHub } from '../../vue.js'
import Tooltip from '../tooltip/Tooltip'

export default {
  name: 'table-header',

  components: { Tooltip },

  props: {
    filter: {
      required: true,
      type: Object
    }
  },

  computed: {
    // only show the sort buttons if the title has a filter
    hasOptions() {
      return this.filter.options != undefined || this.filter.name != undefined
    },
    hasTooltip() {
      return 'tooltip' in this.filter
    }
  },

  methods: {
    sort() {
      this.$eventHub.$emit('sort', this.filter.name)
    }
  }
}
</script>
