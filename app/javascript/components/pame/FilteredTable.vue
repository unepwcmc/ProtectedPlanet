<template>
  <div class="filtered-table relative pame">
    <filters
      :filters="filters" 
      :total-items="totalItems"
    />
    <table class="table table--pame">
      <pame-table-head :filters="attributes" />
      <tbody class="table__tbody table__tbody--list">
        <list
          v-for="(item, key) in items" 
          :key="key"
          :attributes="attributes"
          :is-last="key === items.length - 1"
          :item="item"
        />
      </tbody>
      <tbody class="table__tbody table__tbody--row">
        <row
          v-for="(item, key) in items" 
          :key="key"
          :item="item"
        />
      </tbody>
    </table>

    <pame-pagination 
      :current-page="currentPage" 
      :items-per-page="itemsPerPage" 
      :total-items="totalItems"
      :total-pages="totalPages" 
      @updated:page="getNewItems" />
  </div>
</template>

<script>
import axios from 'axios'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import Filters from './Filters.vue'
import PameTableHead from './PameTableHead.vue'
import Row from './Row.vue'
import List from './List.vue'
import PamePagination from './PamePagination.vue'

export default {
  name: 'FilteredTable',

  components: { Filters, PameTableHead, Row, List, PamePagination },

  mixins: [mixinAxiosHelpers],

  props: {
    endpoint: {
      required: true,
      type: String
    },
    filters: { type: Array, default: () => [] },
    attributes: { type: Array, default: () => [] },
    json: { type: Object, default: () => {} }
  },

  data() {
    return {
      currentPage: 1,
      itemsPerPage: 50,
      totalItems: 0,
      totalPages: 0,
      items: [],
      sortDirection: 1
    }
  },

  created() {
    this.updateProperties(this.json)
  },

  mounted() {
    this.$eventHub.$on('getNewItems', this.getNewItems)
  },

  methods: {
    updateProperties(data) {
      this.currentPage = data.current_page
      this.itemsPerPage = data.per_page
      this.totalItems = data.total_entries
      this.totalPages = data.total_pages
      this.items = data.items
    },

    getNewItems() {
      let data = {
        requested_page: this.$store.state.pame.requestedPage,
        filters: this.$store.state.pame.selectedFilterOptions
      }

      this.axiosSetHeaders()

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
