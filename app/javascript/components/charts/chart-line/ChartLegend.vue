<template>
  <ul>
    <li v-for="row, index in rows" class="chart__legend-li" :class="themeClass">
      <p class="chart__legend-item">
        <template v-if="showIcons">
          <span v-if="row.line" class="chart__legend-key" :style="lineStyle"></span>
          <span v-else class="chart__legend-key" :style="style(index)"></span>
        </template>

        <span v-if="showNumbers" class="chart__legend-index">{{ index + 1 }}.</span> 

        <span class="chart__legend-title">{{ row.title }}</span>
      </p>

      <span 
        v-if="row.subtitle" 
        class="chart__legend-subtitle"
        v-html="row.subtitle"
      />
    </li>
  </ul>
</template>

<script>
  export default {
    name: 'chart-legend',

    props: {
      rows: {
        required: true,
        type: Array //[ { title: String, subtitle: String } ]
      },
      showIcons: {
        default: true,
        type: Boolean
      },
      showNumbers: {
        default: false,
        type: Boolean
      },
      theme: String,
      colours: Array
    },

    data () {
      return {
        lineStyle: {
          'border-top': 'dashed 1px #871313',
          'background-color': 'transparent',
          'height': 0
        }
      }
    },

    computed: {
      themeClass () {
        return `theme--${this.theme}`
      }
    },

    methods: {
      style (index) {
        let styling = {}

        if(this.colours) {
          const colour = this.colours[index]

          styling['background-color'] = this.colours[index]

          if(colour == '#ffffff') { styling['border'] = 'solid 1px #cccccc' } 
        }

        return styling
      }
    }
  }
</script>