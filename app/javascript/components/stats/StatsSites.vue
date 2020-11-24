<template>
  <div>
    <div class="flex flex-v-center flex-h-between">
      <h2>{{ data.title }}</h2>
      <a 
        class="margin-space--left button--all"
        :href="data.view_all"
        :title="data.text_view_all"
      >
      {{ data.text_view_all }}
      </a>
    </div>

    <div class="cards--search-results-areas preview">
      <a
        class="card__link"
        v-for="(card, i) in data.cards"
        :key="i"
        href="protected_area_path(card.wdpa_id)"
        :title="`View more about the site: ${card.name}`"
      >
        <div class="card__image-placeholder">
          <div alt="title" class="card__image" style="background-image: url(<%= protected_area_cover(card, with_tag: false) %>)"></div>
        </div>

        <div class="card__content">
          <h3 class="card__title">{{ card.name }}</h3>
        </div>
      </a>
    </div>
  </div>
</template>

<script>
export default {
  name: 'StatsSites',

  props: {
    data: {
      required: true,
      type: Object
    }
  }
}
</script>