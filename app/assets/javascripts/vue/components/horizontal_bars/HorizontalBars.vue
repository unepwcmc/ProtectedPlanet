<template>
  <div class="v-horizontal-bars">
    <horizontal-bar v-for="bar, key in bars" 
      :key="key"
      :name="bar.name"
      :km="bar.km"
      :url="bar.url"
      :percent="percent(bar.km)"
    >
    </horizontal-bar>
  </div>
</template>

<script>
  module.exports = {
    name: 'horizontal-bars',

    components: {
      'horizontal-bar': VComponents['vue/components/horizontal_bars/HorizontalBar'],
    },

    props: {
      json: { required: true }
    },

    data: function() {
      return {
        max: 0,
        bars: {}
      }
    },

    created: function() {
      this.bars = this.json
      this.calculateMax()
    },

    methods: {
      calculateMax: function () {
        var array = []

        this.json.forEach(function (dataset) {
          array.push(dataset.km)
        })

        this.max = Math.max.apply(null, array)
      },

      percent: function (km) {
        return Math.round((km / this.max)*100) + '%'
      }
    }
  }
</script>
