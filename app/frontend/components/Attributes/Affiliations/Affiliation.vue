<template>
  <li class="card__logo">
    <img
      class="card__logo-image"
      :src="link.image_url"
      :alt="link.image_alt || imageAltFallback"
    >
    <template v-if="link.affiliation === 'greenlist'">
      <p v-text="translations.green_list_intro" />
      <p
        class="card__subtitle"
        v-text="translations.green_list_type"
      />
      <span v-text="link.type" />

      <template v-if="link.date">
        <p
          class="card__subtitle"
          v-text="translations.green_list_date"
        />
        <span v-text="link.date" />
      </template>

      <template v-if="link.url">
        <a
          class="card__subtitle--link"
          :href="link.url"
          :title="translations.green_list_title"
          target="_blank"
          rel="noopener noreferrer"
        >
          <p v-text="translations.green_list_url" />
          <span class="button--external-link" />
        </a>
      </template>
    </template>
    <a
      class="card__button"
      :href="link.link_url"
      :title="link.link_title"
      target="_blank"
      rel="noopener noreferrer"
      v-text="translations.more"
    />
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { AttributesAffiliationLink, AttributesAffiliationsTranslations } from '@/types/backend'

const props = defineProps<{
  link: AttributesAffiliationLink
  translations: AttributesAffiliationsTranslations
}>()

const imageAltFallback = computed(() => props.link.affiliation === 'greenlist' ? 'Green List' : 'PARCC')
</script>
