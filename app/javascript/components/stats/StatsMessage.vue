<template>
  <div class="card--message">
    <p 
      class="card__warning"
      v-html="data.text"
    />

    <ul class="list--links"
      v-if="data.documents"
    >
      <li 
        class="list__li"
        v-for="(document, i) in data.documents"
        :key="i"
      >
        <span>{{ document.name }}</span>
        <a
          :class="`list__a button--${document.type}`"
          :href="document.url"
          target="_blank"
          :title="document.name"
        >
          {{ document.type }}
        </a>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'StatsMessage',

  props: {
    data: {
      required: true,
      type: Object
    }
  }
}
</script>