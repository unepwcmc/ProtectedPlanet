<template>
  <button class="table-head__sort" @click="sort"></button>
</template>

<script>
export default {
  name: 'table-sort',

  props: {
    sortKey: {
      type: String,
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
      const order = this.sortDirection === 1 ? "ASC" : "DESC"

      this.$store.dispatch('table/updateSortParameters', { field: this.sortKey, direction: order })
      this.$eventHub.$emit('getNewItems')
    }
  }
}  
</script>
