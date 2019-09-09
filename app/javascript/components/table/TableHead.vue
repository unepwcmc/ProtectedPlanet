<template>
  <div class="table__head">
    <div v-for="(heading, index) in headings"
      :key="getVForKey('row', index)"
      class="table__cell--heading"
    >
      {{ heading.title }}
    </div>    
  </div>
</template>

<script>
import mixinId from '../../mixins/mixin-ids'

export default {
  name: 'TableHead',

  mixins: [ mixinId ],

  props: {
    headings: {
      type: Array, // [ { title: String } ]
      required: true
    }
  }
}
</script>