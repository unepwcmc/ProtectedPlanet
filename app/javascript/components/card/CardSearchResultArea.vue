<template>
  <a 
    :class="`card__link card--${geoType}`"
    :href="url"
    title=""
  > 
    <div class="card__image-placeholder">
      <div 
        :alt="title"
        class="card__image"
        :style="{ backgroundImage: `url(${image})` }" 
      />
    </div>

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
    isRegion () { return this.geoType == 'region' },

    isCountry () { return this.countryFlag }
  }
}
</script>