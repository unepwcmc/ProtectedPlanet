<template>
  <div class="table-head">
    <div 
      v-for="(heading, index) in headings"
      :key="getVForKey('row', index)"
      class="table-head__cell"
    >
      <span class="table-head__title">{{ heading.title }}</span>

      <tooltip 
        v-if="!isFirstHeading(index)"
        :on-hover="false" 
        :text="getTooltipText(heading.id)"
        :class="['table-head__tooltip', { 'tooltip--end': isLastHeading(index) }]"
      >
        <slot />  
      </tooltip>

      <table-sort 
        v-if="index !== 0"
        :sort-key="heading.id" 
      />
    </div>    
  </div>
</template>

<script>
import mixinId from '../../mixins/mixin-ids'
import TableSort from './TableSort'
import Tooltip from '../tooltip/Tooltip'

export default {
  name: 'table-head',

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
    },

    isFirstHeading (index) {
      return 0 === index
    },

    isLastHeading (index) {
      return this.headings.length - 1  === index
    }
  }
}
</script>