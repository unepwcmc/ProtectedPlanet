<template>
  <div>
    <div class="flex flex-v-center flex-h-between">
      <h2>{{ title }}</h2>
      <a 
        class="margin-space--left button--all"
        :href="viewAll"
        :title="textViewAll"
      >
        {{ textViewAll }}
      </a>
    </div>

    <div class="cards--search-results-areas preview">
      <a
        v-for="(siteDetail, i) in siteDetails"
        :key="i"
        class="card__link"
        :href="`/${siteDetail.wdpa_id}`"
        :title="`View more about the site: ${siteDetail.name}`"
      >
        <div class="card__image-placeholder">
          <div
            alt="title"
            class="card__image"
            :style="{
              backgroundImage: 'url(' + siteDetail.thumbnail_link + ')'
            }"
          />
        </div>

        <div class="card__content">
          <h3 class="card__title">{{ siteDetail.name }}</h3>
        </div>
      </a>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StatsSites',

  props: {
    siteDetails: {
      required: true,
      type: Array
    },
    textViewAll: {
      required: true,
      type: String
    },
    title: {
      required: true,
      type: String
    },
    viewAll: {
      required: true,
      type: String
    }
  }
}
</script>