<template>
  <div class="filtered-table relative">
    <filters 
      class="filters--pame"
      :filters="filters" 
      :total-items="totalItems"
    />

    <div class="table-head--pame">
      <pame-table-head :filters="attributes" />
    </div>

    <div class="table--pame">
      <row v-for="item, key in items"
        :key="key"
        :item="item">
      </row>
    </div>

    <pame-pagination 
      :current-page="currentPage" 
      :items-per-page="itemsPerPage" 
      :total-items="totalItems" 
      :total-pages="totalPages"
    />
  </div>
</template>

<script>
  import axios from 'axios'
  import { eventHub } from '../vue.js'
  import Filters from './pame-filters/Filters.vue'
  import PameTableHead from './table/PameTableHead.vue'
  import Row from './table/Row.vue'
  import PamePagination from './pagination/PamePagination.vue'

  export default {
    name: 'filtered-table',

    components: { Filters, PameTableHead, Row, PamePagination },

    props: {
      endpoint: {
        required: true,
        type: String
      },
      filters: { type: Array },
      attributes: { type: Array },
      json: { type: Object }
    },

    data () {
      return {
        currentPage: 1,
        itemsPerPage: 0,
        totalItems: 0,
        totalPages: 0,
        items: [],
        sortDirection: 1
      }
    },

    created () {
      this.updateProperties(this.json)
    },

    mounted () {
      eventHub.$on('getNewItems', this.getNewItems)
    },

    methods: {
      updateProperties (data) {
        this.currentPage = data.current_page
        this.itemsPerPage = data.per_page
        this.totalItems = data.total_entries
        this.totalPages = data.total_pages
        this.items = data.items
      },

      getNewItems () {
        let data = {
          requested_page: this.$store.state.requestedPage,
          filters: this.$store.state.selectedFilterOptions
        }

        const csrf = document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')
        axios.defaults.headers.common['X-CSRF-Token'] = csrf
        axios.defaults.headers.common['Accept'] = 'application/json'

        axios.post(this.endpoint, data)
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
