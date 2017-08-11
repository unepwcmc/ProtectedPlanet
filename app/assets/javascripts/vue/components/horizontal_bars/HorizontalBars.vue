<template>
  <div class="v-horizontal-bars">
    <horizontal-bar v-for="bar, key in bars" 
      :key="key"
      :name="bar.name"
      :km="bar.km"
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
      // json: {}
    },

    data () {
      return {
        max: 0,
        bars: {},
        data: [
          {
            name: "Ross Sea Marine Reserve",
            km: 1550000
          },
          {
            name: "Papahānaumokuākea Marine National Monument",
            km: 1510000
          },
          {
            name: "Natural Park of the Coral Sea",
            km: 1292967
          },
          {
            name: "Marianas Trench Marine National Monument",
            km: 345400
          }
        ]
      }
    },

    created () {
      //this.bars = this.json 
      this.bars = this.data
      this.calculateMax()
    },

    methods: {
      calculateMax: function () {
        var array = []

        for ( dataset of this.data) {
          array.push(dataset.km)
        }

        this.max = Math.max(...array)
      },

      percent: function (km) {
        return Math.round((km / this.max)*100) + '%'
      }
    }
  }
</script>
