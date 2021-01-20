<template>
  <div class="card--message">
    <p 
      class="card__warning"
      v-html="text"
    />

    <ul class="list--links"
      v-if="documents"
    >
      <li 
        class="list__li"
        v-for="(document, i) in documents"
        :key="i"
      >
        <span>{{ document.name }}</span>
        <a
          :class="`list__a button--${document.type}`"
          :href="document.url"
          target="_blank"
          :title="document.name"
        >
          {{ document.button_text }}
        </a>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'StatsMessage',

  props: {
    documents:{
      type: Array
    },
    link: {
      type: String
    },
    text:{
      required: true,
      type: String
    }
  },

  computed: {
    hasDocuments () {
      return this.documents && this.documents.length > 1
    }
  }
}
</script>