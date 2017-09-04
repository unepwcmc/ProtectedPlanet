<template>
  <div class="v-interactive-treemap">
    <div class="flex-row-wrap justify-content-end">
      <div class="flex-2-fiths counter v-interactive-treemap__info-panel">
        <div class
        ="v-interactive-treemap__info">
          <p class="v-interactive-treemap__title">
            <a :href="'country/'+iso" class="button--basic-link" target="_blank" :title="'Visit the ' + country + ' country page'">{{ country }}</a>
          </p>

          <p>{{ country }} and its <a :href="overseasTerritoriesURL" target="_blank">{{ totalOverseasTerritories }} overseas {{ correctEnding('countries', totalOverseasTerritories) }} and {{ correctEnding('territories', totalOverseasTerritories) }}</a> have a combined area of {{ styledNumber(totalMarineArea) }}km²</p>

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
              of their overseas {{ correctEnding('territories', totalOverseasTerritories) }} waters are protected
            </p>
          </div>
        </div>
      </div>

      <div class="flex-3-fiths v-interactive-treemap__treemap">
        <treemap :json="json" :interactive="true" v-on:mouseenter="updatePercent"></treemap>
        <p class="v-interactive-treemap__instruction u-show-desktop">Hover over a country to see percentage and actual coverage</p>
      </div>
    </div>

    <div class="v-interactive-treemap__list">
      <div v-for="child in json.children" class="v-interactive-treemap__list-item">

        <p class="v-interactive-treemap__title">
          <a :href="'country/'+ child.iso" class="button--basic-link" target="_blank" :title="'Visit the ' + child.name + ' country page'">{{ child.name }}</a>
        </p>

        <p>{{ child.country }} and its <a :href="overseasTerritoriesURL" target="_blank">{{ child.totalOverseasTerritories }} overseas {{ correctEnding('countries', child.totalOverseasTerritories) }} and {{ correctEnding('territories', child.totalOverseasTerritories) }}</a> have a combined area of {{ styledNumber(child.totalMarineArea) }}km²</p>

        <p class="v-interactive-treemap__stat">
          <span class="v-interactive-treemap__percent">{{ styledNumber(child.nationalPercentage) }}%</span>
          <span class="v-interactive-treemap__km">
            ({{ styledNumber(child.national) }}km²)
          </span>
          of their national waters are protected
        </p>

        <p class="v-interactive-treemap__stat">
          <span class="v-interactive-treemap__percent">{{ styledNumber(child.overseasPercentage) }}%</span>
          <span class="v-interactive-treemap__km">
           ({{ styledNumber(child.overseas) }}km²)
          </span>
          of their overseas {{ correctEnding('territories', child.totalOverseasTerritories) }} waters are protected
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
        country: '',
        iso: '',
        totalMarineArea: 0,
        totalOverseasTerritories: 0,
        overseasTerritoriesURL: '',
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
      updatePercent: function(data) {
        this.country = data.country
        this.iso = data.iso
        this.totalMarineArea = data.totalMarineArea
        this.totalOverseasTerritories = data.totalOverseasTerritories
        this.overseasTerritoriesURL = data.overseasTerritoriesURL
        this.national = data.national
        this.nationalPercentage = data.nationalPercentage
        this.overseas = data.overseas
        this.overseasPercentage = data.overseasPercentage
      },

      styledNumber: function(number) {
        return (Math.ceil(number * 100)/100).toLocaleString()
      },

      correctEnding: function (word, territories) {
        var string = word

        if(territories == 1) { string = string.slice(0, -3) + 'y' }

        return string
      }
    }
  }
</script>
