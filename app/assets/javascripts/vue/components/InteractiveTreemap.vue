<template>
  <div class="v-interactive-treemap flex-row-wrap justify-content-end">
    <div class="flex-2-thirds v-interactive-treemap__treemap">
      <treemap :json="json" :interactive="true" v-on:mouseover="updatePercent"></treemap>
      <p class="v-interactive-treemap__instruction">Hover over a country to see percentage and actual coverage</p>
    </div>

    <div class="flex-1-third counter">
      <h3 class="text--48">{{ country }}</h3>
      <h3 class="header--h3-insights">Percent of national waters covered by Protected Area</h3>
      <p class="text--120"><counter :total="percent" :config="counterConfig"></counter>%</p>

      <h3 class="header--h3-insights">km² protected</h3>
      <p class="text--48"><counter :total="km" :config="counterConfig"></counter>km²</p>
    </div>
  </div>
</template>

<script>
  module.exports = {
    name: 'interactive-treemap',

    components: { 
      'treemap': VComponents['vue/charts/Treemap'],
      'counter': VComponents['vue/components/Counter']
    },

    props: {
      test: String
    },

    data() {
      return {
        country: "",
        percent: 0,
        km: 0,
        counterConfig: {
          speed: 20,
          divisor: 8
        },
        json: {
          "name": "ocean areas",
          "children": [
            {
              "name": "",
              "size": 10
            },
            {
              "name": "protected areas",
              "children": [
                {
                  "name": "Cook Islands",
                  "size": 1
                },
                {
                  "name": "Grenada",
                  "size": 3
                },
                {
                  "name": "Indonesia",
                  "size": 1
                },
                {
                  "name": "Marshall Islands",
                  "size": 5
                }
              ]
            }
          ]
        }
      }
    },

    methods: {
      updatePercent: function(data){
        this.country = data.country
        this.percent = data.percent
        this.km = data.km
      },

      updateCountry: function(data){
        this.country = data
      }
    }
  }  
</script>
