<template>
  <div
    class="ct-attributes-pame
    tw-global-pdf-export__break-inside-avoid"
  >
    <h3
      v-if="title"
      class="ct-attributes-pame__title
      tw-global-pdf-export__break-after-avoid"
      v-text="title"
    />
    <ul
      v-if="Object.keys(pameAttributes).length > 0"
      class="ct-attributes-pame__list"
    >
      <li
        v-for="(years, methodology) in pameAttributes"
        :key="methodology"
        class="ct-attributes-pame__item
        tw-global-pdf-export__break-inside-avoid"
        :class="{
          'ct-attributes-pame__item--for-pdf': forPdf
        }"
      >
        <span
          class="ct-attributes-pame__item-title"
          v-text="methodology"
        />
        <span
          class="ct-attributes-pame__item-value"
          v-text="years.join(', ')"
        />
      </li>
    </ul>
    <p
      v-else
      class="ct-attributes-pame__no-info"
      v-text="translations.no_information"
    />
  </div>
</template>

<script setup lang="ts">
import type { AttributesPameYearsByMethod, AttributesPameListTranslations } from '@/types/backend'

defineProps<{
  pameAttributes: AttributesPameYearsByMethod
  title?: string
  translations: AttributesPameListTranslations
  forPdf: boolean
}>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-pame {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-attributes-pame__title {
  @apply tw-shared-card-sub-title;
}

.ct-attributes-pame__list {
  @apply tw-shared-base-flex-col;
}

.ct-attributes-pame__item {
  @apply
  tw-shared-base-flex-gap-3
  flex-wrap
  md:items-center
  py-4
  px-3.5
  odd:bg-theme-grey-xlight;
}

.ct-attributes-pame__item--for-pdf {
  @apply tw-shared-list-stripes-item-for-pdf;
}

.ct-attributes-pame__item-title {
  @apply
  tw-shared-list-stripes-title
  max-w-full;
}

.ct-attributes-pame__item-value {
  @apply tw-shared-list-stripes-value;
}

.ct-attributes-pame__no-info {
  @apply tw-shared-card-no-info-text;
}
</style>
