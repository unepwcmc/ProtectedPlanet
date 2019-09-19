<template>
  <div class="table-head">
    <div v-for="(heading, index) in headings"
      :key="getVForKey('row', index)"
      class="table-head__cell"
    >
      {{ heading.title }}

      <table-sort :sort-key="heading.id" />

      <tooltip 
        v-if="index !== 0"
        :on-hover="false" 
        :text="getTooltipText(heading.id)"
        class="carousel__tooltip"
      >
        <i class="icon--info-circle block"></i>
      </tooltip>
    </div>    
  </div>
</template>

<script>
import mixinId from '../../mixins/mixin-ids'
import TableSort from './TableSort'
import Tooltip from '../tooltip/Tooltip'

export default {
  name: 'TableHead',

  components: { TableSort, Tooltip },

  mixins: [ mixinId ],

  props: {
    headings: {
      type: Array, // [ { id: String, title: String } ]
      required: true
    },
    tooltipArray: {
      type: Array, // [ { id: String, title: String, text: String } ]
      required: true
    }
  },

  methods: {
    getTooltipText (id) {
      const tooltip = this.tooltipArray.find(obj => {
        return obj.id === id
      })
      
      return tooltip !== undefined ? tooltip.text : ''
    }
  }
}
</script>