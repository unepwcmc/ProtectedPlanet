<template>
  <div class="card--stats-coverage card--stats-half">
    <h2 class="card__h2">{{ title }}</h2>

    <div class="card__content">
      <div class="card__chart">
        <div class="chart--square">
          <span 
            :class="`chart__area theme--${type}`" 
            :style="`width: ${protectedPercentage}%; height: ${protectedPercentage}%;`"
          ></span>
        </div>
      </div>

      <div>
        <div class="card__stat-large">
          <span class="card__number-large block">{{ protectedPercentage }}%</span> {{ textCoverage }}
        </div>

        <div>
          <p class="card__stat">
            <span class="card__number block">{{ protectedKm2 }}km<sup>2</sup></span> {{ textProtected }}
          </p>
          <p class="card__stat">
            <span class="card__number block">{{ totalKm2 }}km<sup>2</sup></span> {{ textTotal }}
          </p>
        </div>

        <div>
          <p 
            class="card__stat"
            v-if="hasNationalReport"
          >
            <span class="card__number block">
              {{ protectedNationalReport }}%
            </span>
            {{ nationalReportVersion }}{{ textNationalReport }}
          </p>
          <div 
            class="card__subsection"
            v-if="hasPameData"
          >
            <p class="card__subtitle">PAME</p>

            <p class="card__stat">
                <span class="card__number block"> {{ pamePercentage }}% </span> {{ textPameAssessments }}
              </p>
              <p class="card__stat">
                <span class="card__number block">{{ pameKm2 }}km<sup>2</sup></span> {{ textPame }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StatsCoverage',

  props: {
    nationalReportVersion:{
      type: Number
    },
    pameKm2:{
      type: String
    },
    pamePercentage:{
      type: Number
    },
    protectedKm2:{
      required: true,
      type: String
    },
    protectedNationalReport:{
      type: Number
    },
    protectedPercentage:{
      required: true,
      type: Number
    },
    textCoverage:{
      required: true,
      type: String
    },
    textNationalReport:{
      type: String
    },
    textPame:{
      type: String
    },
    textPameAssessments:{
      type: String
    },
    textProtected:{
      required: true,
      type: String
    },
    textTotal:{
      required: true,
      type: String
    },
    title:{
      required: true,
      type: String
    },
    totalKm2:{
      required: true,
      type: String
    },
    type:{
      required: true,
      type: String
    }
  },

  computed: {
    hasNationalReport () {
      return this.protectedNationalReport != null && this.nationalReportVersion != null
    },
    
    hasPameData () {
      return this.pamePercentage != null && this.pameKm2 != null
    }
  }
}
</script>