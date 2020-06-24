<template>
  <div class="table-head__cell flex flex-h-center">
    <span class="table-head__title">{{ filter.title }}</span>

    <tooltip v-if="hasTooltip" :text="filter.tooltip"></tooltip>

    <div v-if="hasOptions" class="table__sorting" @click="sort()">
      <span alt="Sort results" class="table__sort table__sort--ascending"></span>
      <span alt="Sort results" class="table__sort table__sort--descending"></span>
    </div>
  </div>
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
      hasOptions () {
        return this.filter.options != undefined || this.filter.name != undefined
      },
      hasTooltip () {
        return 'tooltip' in this.filter
      }
    },

    methods: {
      sort () {
        eventHub.$emit('sort', this.filter.name)
      }
    }
  }
</script>
