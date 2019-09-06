<template>
  <div>
<!--     <table-head
      :headings="json.head"
    /> -->

    <table-row 
      v-for="row in json.body"
      :row="row"
    />
  </div>  
</template>

<script>
import TableRow from './TableRow'

export default {
  name: 'VTable',

  components: { TableRow },

  props: {
    json: {
      type: Object,
      required: true
    }
  }
} 
</script>