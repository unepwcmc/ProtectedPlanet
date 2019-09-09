<template>
  <div>
    <table-head
      :headings="json.head"
    />

    <table-row 
      v-for="(row, index) in json.body"
      :key="getVForKey('row', index)"
      :row="row"
    />
  </div>  
</template>

<script>
import mixinId from '../../mixins/mixin-ids'
import TableHead from './TableHead'
import TableRow from './TableRow'

export default {
  name: 'VTable',

  components: { TableHead, TableRow },

  mixins: [ mixinId ],

  props: {
    json: {
      type: Object,
      required: true
    }
  }
} 
</script>