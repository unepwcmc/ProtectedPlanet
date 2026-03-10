<template>
  <li class="card__logo">
    <img :src="link.image_url" :alt="link.image_alt || imageAltFallback" class="card__logo-image" />

    <template v-if="link.affiliation === 'greenlist'">
      <p>{{ translations.green_list_intro }}</p>
      <p class="card__subtitle">{{ translations.green_list_type }}</p>
      <span>{{ link.type }}</span>

      <template v-if="link.date">
        <p class="card__subtitle">{{ translations.green_list_date }}</p>
        <span>{{ link.date }}</span>
      </template>

      <template v-if="link.url">
        <a
          class="card__subtitle--link"
          :href="link.url"
          :title="translations.green_list_title"
          target="_blank"
          rel="noopener noreferrer"
        >
          <p>{{ translations.green_list_url }}</p>
          <span class="button--external-link"></span>
        </a>
      </template>
    </template>

    <a
      class="card__button"
      :href="link.link_url"
      :title="link.link_title"
      target="_blank"
      rel="noopener noreferrer"
    >
      {{ translations.more }}
    </a>
  </li>
</template>

<script>
export default {
  name: 'AttributesAffiliation',

  props: {
    link: {
      type: Object,
      required: true,
      default: () => ({})
    },
    translations: {
      type: Object,
      required: true,
      default: () => ({
        green_list_intro: '',
        green_list_type: '',
        green_list_date: '',
        green_list_title: '',
        green_list_url: '',
        more: 'More'
      })
    }
  },

  computed: {
    imageAltFallback () {
      return this.link.affiliation === 'greenlist' ? 'Green List' : 'PARCC'
    }
  }
}
</script>
