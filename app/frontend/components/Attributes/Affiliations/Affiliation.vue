<template>
  <li
    class="ct-attributes-affiliations-affiliation
  tw-global-pdf-export__break-inside-avoid"
  >
    <img
      class="ct-attributes-affiliations-affiliation__image"
      :src="link.image_url"
      :alt="link.image_alt || imageAltFallback"
    >
    <template v-if="link.affiliation === 'greenlist'">
      <p
        class="ct-attributes-affiliations-affiliation__green-list-intro"
        v-text="translations.green_list_intro"
      />
      <div class="ct-attributes-affiliations-affiliation__green-list-category">
        <p
          class="ct-attributes-affiliations-affiliation__subtitle"
          v-text="translations.green_list_type"
        />
        <span
          class="ct-attributes-affiliations-affiliation__text"
          v-text="link.type"
        />
      </div>
      <div
        v-if="link.date"
        class="ct-attributes-affiliations-affiliation__green-list-category"
      >
        <p
          class="ct-attributes-affiliations-affiliation__subtitle"
          v-text="translations.green_list_date"
        />
        <span
          class="ct-attributes-affiliations-affiliation__text"
          v-text="link.date"
        />
      </div>

      <template v-if="link.url">
        <a
          class="ct-attributes-affiliations-affiliation__subtitle-link"
          :href="link.url"
          :title="translations.green_list_title"
          target="_blank"
          rel="noopener noreferrer"
        >
          <p v-text="translations.green_list_url" />
          <IconCircleChevron class="ct-attributes-affiliations-affiliation__external-link-icon" />
        </a>
      </template>
    </template>
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { AttributesAffiliationLink, AttributesAffiliationsTranslations } from '@/types/backend'
import IconCircleChevron from '@/components/Icon/CircleChevron.vue'

const props = defineProps<{
  link: AttributesAffiliationLink
  translations: AttributesAffiliationsTranslations
}>()

const imageAltFallback = computed(() => props.link.affiliation === 'greenlist' ? 'Green List' : 'PARCC')
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-affiliations-affiliation {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-attributes-affiliations-affiliation__image {
  @apply w-25;
}

.ct-attributes-affiliations-affiliation__green-list-intro {
  @apply tw-shared-font-hind-siliguri__light-base-grey-black;
}

.ct-attributes-affiliations-affiliation__green-list-category {
  @apply tw-shared-base-flex-col-gap-1;
}

.ct-attributes-affiliations-affiliation__subtitle {
  @apply tw-shared-list-stripes-title;
}

.ct-attributes-affiliations-affiliation__text {
  @apply tw-shared-list-stripes-value;
}

.ct-attributes-affiliations-affiliation__subtitle-link {
  @apply
  tw-shared-base-flex-gap-1
  items-center
  no-underline;
}

.ct-attributes-affiliations-affiliation__external-link-icon {
  @apply tw-shared-list-underline-link-icon;
}
</style>
