<template>
  <div class="table-head">
    <div v-for="(heading, index) in headings"
      :key="getVForKey('row', index)"
      class="table-head__cell"
    >
      {{ heading.title }}

      <table-sort :sort-key="heading.id" />
    </div>    
  </div>
</template>

<script>
import mixinId from '../../mixins/mixin-ids'
import TableSort from './TableSort'

export default {
  name: 'TableHead',

  components: { TableSort },

  mixins: [ mixinId ],

  props: {
    headings: {
      type: Array, // [ { title: String } ]
      required: true
    }
  }
}
</script>