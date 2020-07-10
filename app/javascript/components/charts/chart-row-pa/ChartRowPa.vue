<template>
  <div class="chart--row-pa">
    <div class="chart__row">
      <div 
        :class="['chart__bar', theme]" 
        :style="{ width: percent + '%' }"
      >
        <div 
          class="chart__coverage" 
          :style="{ width: coverage + '%' }"
        >
          <span class="chart__coverage-label">{{ coverage }}%</span>    
        </div>

        <span class="chart__bar-label">{{ percent }}%</span>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'chart-row-pa',

    props: {
      coverage: {
        type: String,
        required: true
      },
      percent: {
        type: String,
        required: true
      },
      theme: {
        type: String
      }
    }
  }
</script>