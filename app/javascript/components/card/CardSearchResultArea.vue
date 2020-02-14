<template>
    <a 
      class="card__link"
      :href="url"
      title=""
    >
      <i class="card__icon--region-large" />
      
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
        v-html="areas"
      />
    </div>

    <div class="card__groups">
      <p class="card__group flex flex-v-center">
        <i class="card__icon--region" />
        <span>Europe</span>
      </p>
      <p class="card__group flex flex-v-center">
        <i class="card__icon--flag" />
        <span>France</span>
      </p>
    </div>
  </a>
</template>

<script>
export default {
  name: 'CardSearchResultArea',

  props: {
    title: {
      type: String,
      required: true
    },
    image: {
      type: String,
      required: false
    },
    areas: {
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