<template>
  <div 
    class="filters--sidebar"
    v-show="isActive"
  >
    <div class="filter__pane">
      <div class="filter__pane-topbar">
        <span 
          class="filter__pane-title"
          v-html="title"
        />
      </div>

      <div class="filter__filter-groups">
        <div
          v-for="filterGroup, index in filterGroups"
          :key="index"
          class="filter__group"
        >
          <h3>{{ filterGroup.title }}</h3>
          
          <v-filter
            v-for="filter, index in filterGroup.filters"
            :key="`${filter.id}-${index}`"
            :id="filter.id"
            :name="filter.name"
            :options="filter.options"
            :pre-selected="filter.preSelected"
            :title="filter.title"
            :type="filter.type"
            v-on:update:filter="updateFilterGroup"
          />
        </div>
      </div>

      <span 
        class="filter__pane-view"
        v-html="filterCloseText"
        @click="toggleFilterPane"
      />
    </div>
  </div>
</template>

<script>
import vFilter from './vFilter'

export default {
  name: 'filters-search',

  components: { vFilter },

  props: {
    filterCloseText: {
      required: true,
      type: String
    },
    filterGroups: {
      required: true,
      type: Array // [ { title: String, filters: [ { id: String, name: String, title: String, options: [ { id: String, title: String }], type: String } ] } ]
    },
    isActive: {
      required: true,
      type: Boolean
    },
    title: {
      required: true,
      type: String
    }
  },

  data () {
    return {
      activeFilterOptions: {},
      resetting: false
    }
  },

  methods: {
    reset () {
      this.resetting = true
      this.activeFilterOptions = {}
    },

    toggleFilterPane () {
      this.$emit('toggle:filter-pane')
    },

    updateFilterGroup (updatedFilter) {
      if(this.resetting) {
        this.resetting = false
        return false
      }

      this.activeFilterOptions[updatedFilter.id] = updatedFilter.options
      
      this.$emit('update:filter-group', this.activeFilterOptions)
    }
  }
}
</script>
