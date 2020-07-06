<template>
  <a 
    :class="`card__link card--${geoType}`"
    :href="url"
    title=""
  >
    <i 
      v-if="isRegion"
      class="card__icon--region-large" 
    />

    <i
      v-if="isCountry" 
      class="card__icon--flag-large"
      :style="{ backgroundImage: `url(${countryFlag})` }"
    />

    <div 
      v-if="image" 
      :alt="title"
      class="card__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
    <div 
      v-else 
      class="card__image-placeholder"
    />

    <div class="card__content">
      <h3 
        v-html="title"
        class="card__title"
      />
      <span
        v-if="totalAreas"
        v-html="totalAreas"
      />
    </div>

    <!-- <div 
      v-if="hasCountriesOrRegion"
      class="card__groups"
    >
      <p 
        v-if="hasCountries"
        v-for="country in countries"
        class="card__group flex flex-v-center"
      >
        <i 
          class="card__icon--flag" 
          :style="{ backgroundImage: `url(${country.flag})` }"
        />
        <span 
          v-html="country.title"
        />
      </p>

      <p 
        v-if="hasRegion"
        class="card__group flex flex-v-center"
      >
        <i class="card__icon--region" />
        <span v-html="region" />
      </p>
    </div> -->
  </a>
</template>

<script>
export default {
  name: 'card-search-result-area',

  props: {
    geoType: {
      type: String,
      required: true
    },
    image: String,
    countryFlag: String,
    // countries: Array,
    // region: String,
    totalAreas: String,
    title: {
      type: String,
      required: true
    },
    url: {
      type: String,
      required: true
    }
  },

  computed: {
    // hasCountries () { return this.countries },

    // hasCountriesOrRegion () {
    //   return this.hasCountries || this.hasRegion
    // },

    isRegion () { return this.geoType == 'region' },

    isCountry () { return this.countryFlag }
  }
}
</script>