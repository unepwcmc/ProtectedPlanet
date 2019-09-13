<template>
  <button class="table-head__sort" @click="sort"></button>
</template>

<script>
import { eventHub } from '../../vue.js'

export default {
  name: 'TableSort',

  props: {
    sortKey: {
      required: true
    }
  },

  data () {
    return {
      sortDirection: 1
    }
  },

  methods: {
    sort () {
      this.sortDirection = this.sortDirection * -1
      const order = this.sortDirection == 1 ? "ASC" : "DESC"

      this.$store.dispatch('table/updateSortParameters', { field: this.sortKey, direction: order })
      eventHub.$emit('getNewItems')
    }
  }
}  
</script>
