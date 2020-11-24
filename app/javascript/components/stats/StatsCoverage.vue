<template>
  <div class="card--stats-coverage card--stats-half">
    <h2 class="card__h2">{{ data.title }}</h2>

    <div class="card__content">
      <div class="card__chart">
        <div class="chart--square">
          <span 
            :class="`chart__area theme--${data.type}`" 
            :style="`width: ${data.protected_percentage}%; height: ${data.protected_percentage}%;`"
          ></span>
        </div>
      </div>

      <div>
        <div class="card__stat-large">
          <span class="card__number-large block">{{ data.protected_percentage }}%</span> {{ data.text_coverage }}
        </div>

        <div>
          <p class="card__stat">
            <span class="card__number block">{{ data.protected_km2 }}km<sup>2</sup></span> {{ data.text_protected }}
          </p>
          <p class="card__stat">
            <span class="card__number block">{{ data.total_km2 }}km<sup>2</sup></span> {{ data.text_total }}
          </p>
        </div>

        <div>
          <p 
            class="card__stat"
            v-if="data.protected_national_report && data.national_report_version"
          >
            <span class="card__number block">
              {{ data.protected_national_report }}%
            </span>
            {{ data.national_report_version }}{{ data.text_national_report }}
          </p>
          <div 
            class="card__subsection"
            v-if="data.pame_percentage && data.pame_km2"
          >
            <p class="card__subtitle">PAME</p>

            <p class="card__stat">
                <span class="card__number block"> {{ data.pame_percentage }}% </span> {{ data.text_pame_assessments }}
              </p>
              <p class="card__stat">
                <span class="card__number block">{{ data.pame_km2 }}km<sup>2</sup></span> {{ data.text_pame }}
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
    data: {
      required: true,
      type: Object
    }
  }
}
</script>