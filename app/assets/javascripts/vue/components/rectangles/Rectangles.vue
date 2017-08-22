<template>
  <div class="v-rectangles">
    <rectangle v-for="rectangle, key in rectangles"
      :key="key"
      :title="rectangle.title"
      :km="rectangle.km"
      :percent="percent(rectangle.km)"
      :color="color(key)"
    >
    </rectangle>
  </div>
</template>

<script>
  module.exports = {
    name: 'rectangles',

    components: {
      'rectangle': VComponents['vue/components/rectangles/Rectangle']
    },

    props: {
      // json: {}
    },

    data: function() {
      return {
        max: 0,
        rectangles: [],
        colors: [
          '#90BDC4',
          '#729099'
        ],
        data: [
          {
            title: "Total global coverage of all MPA’s",
            km: 20500000
          },
          {
            title: "Total global coverage of largest 20 MPA’s",
            km: 15000000
          }
        ]
      }
    },

    created: function() {
      //this.rectangles = this.json
      this.rectangles = this.data
      this.calculateMax()
    },

    methods: {
      calculateMax: function () {
        var array = []

        this.data.forEach(function (dataset) {
          array.push(dataset.km)
        })

        this.max = Math.max.apply(null, array)
      },

      percent: function (km) {
        return Math.round((km / this.max)*100) + '%'
      },

      color: function(key){
        return this.colors[key]
      }
    },
  }
</script>