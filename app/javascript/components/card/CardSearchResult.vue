<template>
  <a 
    class="card__link"
    :href="url"
    title=""
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

    <img 
      v-if="image" 
      :src="image" 
      alt=""
      class="card__image"
    >
  </a>
</template>

<script>
export default {
  name: 'CardSearchResult',

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