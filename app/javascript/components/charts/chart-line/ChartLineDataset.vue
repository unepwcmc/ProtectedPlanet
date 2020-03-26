<template>
  <g> 
    <path 
      :d="path" 
      fill="none" 
      :stroke="colour.line" 
      stroke-width="2" 
    />

    <circle 
      v-for="datapoint in datapoints"
      :fill="colour.line"
      :cx="datapoint.x" 
      :cy="datapoint.y" 
      r="8" 
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
  export default {
    name: 'chart-line-dataset',

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
      index: {
        type: Number,
        required: true
      },
      middle: {
        type: Object,
        required: true
      },
      path: {
        type: String,
        required: true
      }
    }
  }
</script>