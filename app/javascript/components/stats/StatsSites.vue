<template>
  <div>
    <div class="flex flex-v-center flex-h-between">
      <h2>{{ title }}</h2>
      <a 
        class="margin-space--left button--all"
        :href="view_all"
        :title="text_view_all"
      >
      {{ text_view_all }}
      </a>
    </div>

    <div class="cards--search-results-areas preview">
      <a
        class="card__link"
        v-for="(card, i) in cards"
        :key="i"
        :href="`/${card.wdpa_id}`"
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
    cards: {
      required: true,
      type: Array
    },
    text_view_all: {
      required: true,
      type: String
    },
    title: {
      required: true,
      type: String
    },
    view_all: {
      required: true,
      type: String
    }
  }
}
</script>