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
      json: { required: true }
    },

    data: function() {
      return {
        max: 0,
        rectangles: [],
        colors: [
          '#90BDC4',
          '#729099'
        ]
      }
    },

    created: function() {
      this.rectangles = this.json
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
      },

      color: function(key){
        return this.colors[key]
      }
    },
  }
</script>