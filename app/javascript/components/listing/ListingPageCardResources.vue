<template>
  <div 
    :class="['card', { 'card--link': url }]"
  >
    <a
      v-if="url" 
      class="card__link"
      :href="url"
      title=""
    >
      <p 
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
    </a>

    <template v-else>
      <p 
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
      <a
        v-if="fileUrl"
        class="button--download"
        href="fileUrl"
        target="_blank"
        title=""
      />
      <a
        v-if="linkUrl"
        class="button--link-external"
        href="linkUrl"
        target="_blank"
        title=""
        v-html="linkTitle"
      />
    </template>
  </div>
</template>

<script>
export default {
  name: 'listing-page-card-news',

  props: {
    date: String,
    fileUrl: String,
    linkTitle: String,
    linkUrl: String,
    summary: String,
    title: {
      type: String,
      required: true
    },
    url: String
  },

  computed: {
    class () {
      
    }
  }
}
</script>

