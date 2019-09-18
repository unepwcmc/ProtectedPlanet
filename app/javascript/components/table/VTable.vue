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
      type: Object, // { url: String, params: [ String, String ] }
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
      const storeTable = this.$store.state.table,
        itemsPerPage = this.itemsPerPage,
        requestedPage = storeTable.requestedPage,
        sortDirection = storeTable.sortDirection,
        sortField = storeTable.sortField

      let endpoint = `${this.dataSrc.url}`

      if(this.dataSrc.params) {
        endpoint += '?'

        endpoint += this.dataSrc.params.join('&')
      }

      endpoint = endpoint.replace('PERPAGE', itemsPerPage)
      endpoint = endpoint.replace('PAGE', requestedPage)
      endpoint = endpoint.replace('SORTBY', sortField)
      endpoint = endpoint.replace('ORDER', sortDirection)

      axios.get(endpoint)
        .then(response => {
          this.updateProperties(response.data)
        })
        .catch(function (error) {
          console.log(error)
        })
    }
  }
} 
</script>