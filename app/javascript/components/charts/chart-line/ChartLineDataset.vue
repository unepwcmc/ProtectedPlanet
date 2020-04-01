<template>
  <g> 
    <path 
      :d="path" 
      fill="none" 
      :stroke="colour.line" 
      stroke-width="2" 
    />
    
    <circle
      v-for="datapoint, index in datapoints"
      :fill="colour.line"
      :cx="datapoint.x" 
      :cy="datapoint.y"
      r="7"
      @mouseleave="popupHide()"
      @mouseover="popupShow(datapoint)"
    />
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
      path: {
        type: String,
        required: true
      }
    },

    methods: {
      popupHide () {
        this.$emit('datapoint:mouseleave')
      },

      popupShow (datapoint) {
        this.$emit('datapoint:mouseover', datapoint)
      }
    }
  }
</script>