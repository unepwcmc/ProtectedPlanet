<template>
  <div>
    <sticky-bar 
      trigger-element=".sm-trigger-sticky-bar" 
      class="sticky-bar--basic"
    >
      <div class="sticky-bar__content">
        <v-select-searchable 
          class="v-select--searchable"
          :config="select.config" 
          :options="select.options"
        >
        </v-select-searchable>
          
        <table-head 
          :headings="tableHeadings" 
          class="table-head--horizontal-scroll"
        ></table-head>
      </div>
    </sticky-bar>
        
    <v-table 
      :data-src="tableDataSrc"
      trigger-element="sm-trigger-infinite-scroll"
      class="table--horizontal-scroll"
    ></v-table>
  </div>
</template>

<script>
import StickyBar from '../sticky/StickyBar'
import VSelectSearchable from '../select/VSelectSearchable'
import TableHead from '../table/TableHead'
import VTable from '../table/VTable'

export default {
  name: 'Target11Dashboard',

  components: { StickyBar, TableHead, VSelectSearchable, VTable },

  props: {
    select: {
      required: true,
      type: Object // { config: { id: String, label: String, placeholder: String }, options: [ { } ] }
    },
    tableHeadings: {
      type: Array, // [ { title: String } ]
      required: true
    },
    tableDataSrc: {
      type: Object, // { url: String, params: [ String, String ] }
      required: true
    }
  },

  mounted () {
    this.$eventHub.$on('update:selectedInternal', this.updateTable)
  },

  methods: {
    updateTable (newSelectedInternal) {
      this.$store.dispatch('table/updateSearchTerm', newSelectedInternal.id)
      this.$eventHub.$emit('getNewItems')
    }
  }
}
</script>
