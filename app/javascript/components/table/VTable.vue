<template>
  <div>
    <table-row 
      v-for="(row, index) in items"
      :key="getVForKey('row', index)"
      :row="row"
      :tooltipArray="tooltipArray"
    />

    <span v-if="triggerElement" v-bind:class="loadingSpinnerClasses"></span>
  </div>
</template>

<script>
import axios from 'axios'
import ScrollMagic from 'scrollmagic'
import mixinAxiosHelpers from '../../mixins/mixin-axios-helpers'
import mixinId from '../../mixins/mixin-ids'

import TableRow from './TableRow'

export default {
  name: 'v-table',

  components: { TableRow },

  mixins: [ mixinAxiosHelpers, mixinId ],

  props: {
    dataSrc: {
      type: Object, // { url: String, params: [ String, String ] }
      required: true
    },
    tooltipArray: {
      type: Array, // [ { id: String, title: String, text: String } ]
      required: true
    },
    itemsPerPage: {
      type: Number,
      default: 15
    },
    triggerElement: {
      type: String,
      default: 'default'
    }
  },

  data () {
    return {
      items: () => ({}),
      loadedItems: 0,
      isLoading: false
    }
  },

  computed: {
    loadingSpinnerClasses () {
      return [ 
        this.triggerElement, 
        { 'icon-visible': this.isLoading }, 
        'icon--loading-spinner margin-center'
      ]
    }
  },

  created () {
    this.$eventHub.$on('getNewItems', this.getNewItems)
  },

  mounted () {
    this.getNewItems()

    if(this.triggerElement) { this.scrollMagicHandlers() }
  },

  methods: {
    getNewItems () {
      this.ajaxRequest((data) => { this.items = data.items })
    },

    getMoreItems () {
      const currentPage = this.$store.state.table.requestedPage

      this.$store.dispatch('table/updatePage', currentPage + 1)
      this.ajaxRequest((data) => { this.items = this.items.concat(data.items) })
    },

    ajaxRequest (callback) {
      this.isLoading = true

      const storeTable = this.$store.state.table,
        itemsPerPage = this.itemsPerPage,
        requestedPage = storeTable.requestedPage,
        sortDirection = storeTable.sortDirection,
        sortField = storeTable.sortField,
        searchId = storeTable.searchId
      
      let endpoint = `${this.dataSrc.url}`

      if(this.dataSrc.params) {
        endpoint += '?'

        endpoint += this.dataSrc.params.join('&')
      }

      endpoint = endpoint.replace('PERPAGE', itemsPerPage)
      endpoint = endpoint.replace('PAGE', requestedPage)
      endpoint = endpoint.replace('SORTBY', sortField)
      endpoint = endpoint.replace('ORDER', sortDirection)
      endpoint = endpoint.replace('SEARCHID', searchId)

      this.axiosSetHeaders()

      axios.get(endpoint)
        .then(response => {
          callback(response.data)
          this.loadedItems = this.loadedItems + this.itemsPerPage
          this.isLoading = false
        })
        .catch(error => {
          this.isLoading = false
          console.log(error)
        })
    },

    scrollMagicHandlers () {
      let scrollMagicInfiniteScroll = new ScrollMagic.Controller()

      new ScrollMagic.Scene({ triggerElement: `.${this.triggerElement}` })
        .triggerHook('onEnter')
        .addTo(scrollMagicInfiniteScroll)
        .on('enter', () => {
          this.getMoreItems()
        })
    }
  }
} 
</script>