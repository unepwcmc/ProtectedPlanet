<template>
  <a 
    class="card__link"
    :href="url"
    :title="title"
  >
    <div class="card__content">
      <h3 
        v-html="title"
        class="card__title"
      />

      <p 
        v-if="summary"
        v-html="summary"
        class="card__summary"
      />
    </div>

    <div 
      v-if="image" 
      :alt="title"
      class="card__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
  </a>
</template>

<script>
export default {
  name: 'card-search-result',

  props: {
    title: {
      type: String,
      required: true
    },
    image: {
      type: String,
      required: false
    },
    summary: {
      type: String,
      required: false
    },
    url: {
      type: String,
      required: true
    }
  }
}
</script>