<template>
  <div class="v-interactive-treemap flex-row-wrap justify-content-end">
    <div class="flex-2-thirds">
      <treemap :json="json" :interactive="true" v-on:mouseover="updatePercent"></treemap>
    </div>

    <div class="flex-1-third">
      <h3 class="header--small">Percent of national waters covered by Protected Area</h3>
      <p class="text--120"><counter :total="percent" :config="counterConfig"></counter>%</p>

      <h3 class="header--small">km² protected</h3>
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
        percent: 0,
        km: 0,
        counterConfig: {
          speed: 0,
          divisor: 0
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
        this.percent = data.percent
        this.km = data.km
      }
    }
  }  
</script>
