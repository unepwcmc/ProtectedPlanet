<template>
    <a 
      :class="`card__link card--${geoType}`"
      :href="url"
      title=""
    >
      <i 
        v-if="!hasCountryOrRegion"
        class="card__icon--region-large" 
      />

      <i
        v-if="isCountry" 
        class="card__icon--flag-large"
        :style="{ backgroundImage: `url(${imageFlag})` }"
      />
      
      <img 
        v-if="image" 
        :src="image" 
        alt=""
        class="card__image"
      >

    <div class="card__content">
      <h3 
        v-html="title"
        class="card__title"
      />
      <p
        v-if="areas"
        v-html="areas"
      />
    </div>

    <div 
      v-if="hasCountryOrRegion"
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
    </div>
  </a>
</template>

<script>
export default {
  name: 'card-search-result-area',

  props: {
    areas: {
      type: String,
      required: false
    },
    country: String,
    geoType: {
      type: String,
      required: true
    },
    image: String,
    countryFlag: String,
    countries: Array,
    region: String,
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
    hasCountries () { return this.countries },

    hasCountryOrRegion () {
      return this.hasCountry || this.hasRegion
    },

    hasRegion () { return this.region },

    isCountry () { return this.countryFlag }
  }
}
</script>