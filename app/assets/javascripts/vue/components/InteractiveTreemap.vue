<template>
  <div class="v-interactive-treemap flex-row-wrap justify-content-end">

    <div class="flex-1-third counter">
      <div class="v-interactive-treemap__info u-bg--grey">
        <p class="v-interactive-treemap__title">{{ country }}</p>
        <p>{{ country }} has {{ styledNumber(totalMarineArea) }}km² of national waters, and {{ totalOverseasTerritories }} overseas territories</p>

        <p class="v-interactive-treemap__stat">
          <span class="v-interactive-treemap__percent">
            <counter :total="nationalPercentage" :config="counterConfig"></counter>% 
          </span>
          <span class="v-interactive-treemap__km">
            ({{ styledNumber(national) }}km²)
          </span>
          of their national waters are protected
        </p>

        <p class="v-interactive-treemap__stat">
          <span class="v-interactive-treemap__percent">
            <counter :total="overseasPercentage" :config="counterConfig"></counter>%
          </span>
          <span class="v-interactive-treemap__km">
           ({{ styledNumber(overseas) }}km²)
          </span>
          of their overseas territories waters are protected
        </p>
      </div>
    </div>

    <div class="flex-2-thirds v-interactive-treemap__treemap">
      <treemap :json="data" :interactive="true" v-on:mouseenter="updatePercent"></treemap>
      <p class="v-interactive-treemap__instruction">Hover over a country to see percentage and actual coverage</p>
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
      //json: {}
    },

    data() {
      return {
        country: "",
        // percent: 0,
        // km: 0,
        totalMarineArea: 0,
        totalOverseasTerritories: 0,
        national: 0,
        nationalPercentage: 0,
        overseas: 0,
        overseasPercentage: 0,
        counterConfig: {
          speed: 20,
          divisor: 8
        },
        data: {
          "name": "ocean areas",
          "children": [
            {
              "name": "Australia",
              "totalMarineArea": 7432133,
              "totalOverseasTerritories": 9,
              "national": 3021418,
              "nationalPercentage": 40.65,
              "overseas": 4410704,
              "overseasPercentage": 28.72
            },
            {
              "name": "United Kingdom",
              "totalMarineArea": 7654321,
              "totalOverseasTerritories": 5,
              "national": 12340,
              "nationalPercentage": 12345,
              "overseas": 9234,
              "overseasPercentage": 5432
            },
            {
              "name": "USA",
              "totalMarineArea": 6543211,
              "totalOverseasTerritories": 1,
              "national": 12342,
              "nationalPercentage": 12,
              "overseas": 12344,
              "overseasPercentage": 50
            },
            {
              "name": "France",
              "totalMarineArea": 5432111,
              "totalOverseasTerritories": 1,
              "national": 1232,
              "nationalPercentage": 21,
              "overseas": 1123123,
              "overseasPercentage": 30
            }
          ]
        }
      }
    },

    created () {
      //this.data = this.json
    },

    methods: {
      updatePercent: function(data){
        this.country = data.country
        this.totalMarineArea = data.totalMarineArea
        this.totalOverseasTerritories = data.totalOverseasTerritories
        this.national = data.national
        this.nationalPercentage = data.nationalPercentage
        this.overseas = data.overseas
        this.overseasPercentage = data.overseasPercentage
      },

      styledNumber: function(number){
        return (Math.ceil(number * 10)/10).toLocaleString()
      }
    }
  }  
</script>
