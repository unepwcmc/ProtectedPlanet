<template>
  <div class="flex flex-v-center flex-between">
    <span class="filter__title bold">Filters:</span>

    <data-filter 
      v-for="filter, index in filters"
      :key="`${filter.name}-${index}`"
      :name="filter.name"
      :title="filter.title" 
      :options="filter.options"
      :type="filter.type" 
    />

    <download-csv class=""  :total-items="totalItems"></download-csv>
  </div>
</template>

<script>
  import { eventHub } from "../../vue.js"
  import DataFilter from './DataFilter.vue'
  import DownloadCsv from '../forms/DownloadCsv.vue'

  export default {
    name: "filters",

    components: { DataFilter, DownloadCsv },

    props: {
      filters: {
        required: true,
        type: Array
      },
      totalItems: {
        required: true,
        type: Number
      }
    },

    data () {
      return  {
        children: this.$children
      }
    },

    mounted () {
      this.createSelectedFilterOptions()
      
      this.$eventHub.$on('clickDropdown', this.updateDropdowns)
    },

    methods: {
      updateDropdowns (name) {
        this.children.forEach(filter => {
          filter.isOpen = filter.name == name
        })
      },

      createSelectedFilterOptions () {
        let array = []

        // create an empty array for each filter
        this.filters.forEach(filter => {
          if (filter.name !== undefined && filter.options.length > 0) {
            let obj = {}

            obj.name = filter.name
            obj.options = []
            obj.type = filter.type

            array.push(obj)
          }
        })

        this.$store.commit('setFilterOptions', array)
      },
    }
  }
</script>
