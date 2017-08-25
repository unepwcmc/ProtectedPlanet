<template>
  <div class="v-interactive-treemap">
    <div class="flex-row-wrap justify-content-end">
      <div class="flex-2-fiths counter v-interactive-treemap__info-panel">
        <div class="v-interactive-treemap__info u-bg--grey">
          <p class="v-interactive-treemap__title">{{ country }}</p>
          <p>{{ country }} has {{ styledNumber(totalMarineArea) }}km² of national waters, and <a :href="overseasTerritoriesURL" target="_blank">{{ totalOverseasTerritories }} overseas {{ territories }}</a></p>

          <div class="flex-row-wrap justify-content-between">
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
      </div>

      <div class="flex-3-fiths v-interactive-treemap__treemap">
        <treemap :json="json" :interactive="true" v-on:mouseenter="updatePercent"></treemap>
        <p class="v-interactive-treemap__instruction">Hover over a country to see percentage and actual coverage</p>
      </div>
    </div>

    <div class="v-interactive-treemap__list">
      <div v-for="child in json.children" class="v-interactive-treemap__list-item">
        <p class="v-interactive-treemap__title">{{ child.name }}</p>

        <p>{{ child.country }} has {{ styledNumber(child.totalMarineArea) }}km² of national waters, and {{ child.totalOverseasTerritories }} overseas territories</p>

        <p class="v-interactive-treemap__stat">
          <span class="v-interactive-treemap__percent">
            <counter :total="child.nationalPercentage" :config="counterConfig"></counter>%
          </span>
          <span class="v-interactive-treemap__km">
            ({{ styledNumber(child.national) }}km²)
          </span>
          of their national waters are protected
        </p>

        <p class="v-interactive-treemap__stat">
          <span class="v-interactive-treemap__percent">
            <counter :total="child.overseasPercentage" :config="counterConfig"></counter>%
          </span>
          <span class="v-interactive-treemap__km">
           ({{ styledNumber(child.overseas) }}km²)
          </span>
          of their overseas territories waters are protected
        </p>
      </div>
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
      json: { required: true }
    },

    data: function() {
      return {
        country: "",
        totalMarineArea: 0,
        totalOverseasTerritories: 0,
        overseasTerritoriesURL: "",
        national: 0,
        nationalPercentage: 0,
        overseas: 0,
        overseasPercentage: 0,
        counterConfig: {
          speed: 20,
          divisor: 8
        }
      }
    },

    methods: {
      updatePercent: function(data){
        this.country = data.country
        this.totalMarineArea = data.totalMarineArea
        this.totalOverseasTerritories = data.totalOverseasTerritories
        this.overseasTerritoriesURL = data.overseasTerritoriesURL
        this.national = data.national
        this.nationalPercentage = data.nationalPercentage
        this.overseas = data.overseas
        this.overseasPercentage = data.overseasPercentage
      },

      styledNumber: function(number){
        return (Math.ceil(number * 10)/10).toLocaleString()
      }
    },

    computed: {
      territories: function () {
        var string = 'territories'

        if(this.totalOverseasTerritories == 1) { string = 'territory' }

        return string
      }
    }
  }
</script>
