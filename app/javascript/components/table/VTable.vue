<template>
  <div>
    <table-head
      :headings="tableHeadings"
    />

    <table-row 
      v-for="(row, index) in items"
      :key="getVForKey('row', index)"
      :row="row"
    />
  </div>  
</template>

<script>
import axios from 'axios'
import { setCsrfToken } from '../../helpers/request-helpers'
import { eventHub } from '../../vue.js'
import mixinId from '../../mixins/mixin-ids'

import TableHead from './TableHead'
import TableRow from './TableRow'

export default {
  name: 'VTable',

  components: { TableHead, TableRow },

  mixins: [ mixinId ],

  props: {
    tableHeadings: {
      type: Array,
      required: true
    },
    dataSrc: {
      type: String,
      required: true
    },
    itemsPerPage: {
      type: Number,
      default: 15
    }
  },

  data () {
    return {
      items: {}
    }
  },

  created () {
    eventHub.$on('getNewItems', this.getNewItems)
  },

  mounted () {
    this.getNewItems()
  },

  methods: {
    updateProperties (data) {
      this.items = data.items
    },

    getNewItems () {
      const data = {
        params: {
          items_per_page: this.itemsPerPage,
          requested_page: this.$store.state.table.requestedPage,
          sortDirection: this.$store.state.table.sortDirection,
          sortField: this.$store.state.table.sortField
          // searchTerm: this.$store.state.table.searchTerm
        }
      }

      console.log('getNewItems', data)

      axios.post(this.dataSrc, data)
        .then(response => {
          console.log('success', response)

          this.updateProperties(response.data)
        })
        .catch(function (error) {
          console.log(error)
        })
    }
  }
} 
</script>