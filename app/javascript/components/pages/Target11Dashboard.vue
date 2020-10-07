<template>
  <div>
    <v-select-searchable 
      :config="select.config" 
      :options="select.options"
    />
    
    <span class="sm-trigger-sticky-bar" />

    <sticky-bar 
      trigger-element=".sm-trigger-sticky-bar" 
      class="sticky-bar--target-11"
    >
      <table-head 
        :headings="tableHeadings"
        :tooltipArray="tooltipArray"
        class="table-head--horizontal-scroll"
      >
        <slot />
      </table-head>
    </sticky-bar>

    <v-table 
      :data-src="tableDataSrc"
      :tooltipArray="tooltipArray"
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
  name: 'target-11-dashboard',

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
    },
    tooltipArray: {
      type: Array, // [ { id: String, title: String, text: String } ]
      required: true
    }
  },

  mounted () {
    this.$eventHub.$on('update:selectedInternal', this.updateTable)
  },

  methods: {
    updateTable (newSelectedInternal) {
      this.$store.dispatch('table/updateSearch', newSelectedInternal.id)
      this.$eventHub.$emit('getNewItems')
    }
  }
}
</script>
