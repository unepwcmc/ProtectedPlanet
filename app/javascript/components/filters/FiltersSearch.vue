<template>
  <div v-show="isActive">
    <div class="filter__pane">
      <div class="filter__filter-groups">
        <div 
          v-for="filterGroup in filterGroups"
          class="filter__group"
        >
          <h3>{{ filterGroup.title }}</h3>

          <v-filter 
            v-for="filter in filterGroup.filters"
            :id="filter.id"
            :name="filter.name"
            :options="filter.options"
            :title="filter.title"
            :type="filter.type"
            v-on:update:filter="updateFilterGroup"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import vFilter from './vFilter'

export default {
  name: 'filters-search',

  components: { vFilter },

  props: {
    filterGroups: {
      required: true,
      type: Array // [ { title: String, filters: [ { id: String, name: String, title: String, options: [ { id: String, title: String }], type: String } ] } ]
    },
    isActive: {
      required: true,
      type: Boolean
    }
  },

  data () {
    return {
      activeFilterOptions: [],
      resetting: false
    }
  },

  methods: {
    reset () {
      this.resetting = true
      this.activeFilterOptions = []
    },

    updateFilterGroup (updatedFilter) {
      if(this.resetting) {
        this.resetting = false
        return false
      }

      const filterToUpdate = this.activeFilterOptions.find(filter => {
        return filter.id === updatedFilter.id
      })

      if(filterToUpdate === undefined) {
        this.activeFilterOptions.push(updatedFilter)
      } else {
        filterToUpdate.options = updatedFilter.options
      }

      this.$emit('update:filter-group', this.activeFilterOptions)
    }
  }
}
</script>