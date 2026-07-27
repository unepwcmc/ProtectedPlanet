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
        class="card__title"
        v-html="title"
      />
      <span
        v-if="totalAreas"
        v-html="totalAreas"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
defineProps<{
  geoType: string
  image?: string
  countryFlag?: string
  totalAreas?: string
  title: string
  url: string
}>()
</script>
