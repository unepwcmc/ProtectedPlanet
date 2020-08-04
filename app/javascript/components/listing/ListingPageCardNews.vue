<template>
  <a 
    class="listing__card cards__card bg--grey-xlight"
    :href="url"
    title=""
  >
    <div 
      v-if="image" 
      :alt="title"
      class="card__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
    <div 
      v-else 
      class="card__image"
    >
      <i class="card__icon icon--image" />
    </div>

    <div class="card__content">
      <p 
        v-if="date"
        class="card__date"
        v-html="date"
      >
      <h3 
        class="card__h3"
        v-html="title"
      />
      <p
        class="card__summary"
        v-html="summary"
      />
    </div>
  </a>
</template>

<script>
export default {
  name: 'listing-page-card-news',

  props: {
    date: String,
    image: String,
    summary: String,
    title: {
      type: String,
      required: true
    },
    url: {
      type: String,
      required: true
    }
  }
}
</script>