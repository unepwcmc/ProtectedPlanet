<template>
  <g> 
    <path 
      :d="path" 
      fill="none" 
      :stroke="colour.line" 
      stroke-width="2" 
    />
    
    <chart-popup
      v-for="datapoint, index in datapoints"
      :key="`popup-${index}`"
      :colour="colour.line"
      :x="datapoint.x" 
      :y="datapoint.y" 
      :text="datapoint.value"
    />
    
    <template v-if="hasLegend">
      <circle 
        :fill="colour.line"
        :cx="middle.x" 
        :cy="middle.y" 
        r="18">{{ index + 1 }}
      </circle>

      <text 
        :fill="colour.text"
        :x="middle.x" 
        :y="middle.y" 
        dominant-baseline="middle"
        font-size="18" 
        font-weight="900"
        text-anchor="middle">{{ index + 1 }}
      </text>
    </template>
  </g>
</template>

<script>
  import ChartPopup from './ChartPopup.vue'

  export default {
    name: 'chart-line-dataset',

    components: { ChartPopup },

    props: {
      colour: {
        type: Object,
        required: true
      },
      datapoints: {
        type: Array
      },
      hasLegend: {
        default: false,
        type: Boolean
      },
      path: {
        type: String,
        required: true
      }
    }
  }
</script>