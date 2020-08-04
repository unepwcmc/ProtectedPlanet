<template>
  <div class="listing__card card">
    <a
      v-if="url" 
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
  name: 'listing-page-list-news',

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
  }
}
</script>

