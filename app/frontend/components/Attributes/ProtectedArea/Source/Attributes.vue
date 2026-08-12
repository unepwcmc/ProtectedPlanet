<template>
  <div
    class="ct-attributes-protected-area-source"
    :class="
      { 'ct-attributes-protected-area-source--for-pdf': forPdf }"
  >
    <h2
      v-if="title"
      class="ct-attributes-protected-area-source__title"
      v-text="title"
    />
    <ul class="ct-attributes-protected-area-source__list">
      <li
        v-for="(source, index) in sourceAttributes"
        :key="`${index}sourceAttributes`"
        class="ct-attributes-protected-area-source__item"
      >
        <span
          class="ct-attributes-protected-area-source__item-title"
          v-text="source.title"
        />
        <span
          class="ct-attributes-protected-area-source__item-date"
          v-text="`${translations.updated}: ${source.date_updated}`"
        />
        <span
          class="ct-attributes-protected-area-source__item-party"
          v-text="source.resp_party"
        />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import type { AttributesProtectedAreaSourcesTranslations, StatsSourceItem } from '@/types/backend'

defineProps<{
  title?: string
  sourceAttributes: StatsSourceItem[]
  translations: AttributesProtectedAreaSourcesTranslations
  forPdf: boolean
}>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-protected-area-source {
  @apply tw-shared-base-flex-col-gap-3;
}

.ct-attributes-protected-area-source--for-pdf {
  @apply border-b;
}

.ct-attributes-protected-area-source__title {
  @apply tw-shared-card-sub-title;
}

.ct-attributes-protected-area-source__list {
  @apply
  tw-shared-base-flex-col
  tw-shared-list-underline-scrollbar
  w-full;
}

.ct-attributes-protected-area-source__item {
  @apply
  tw-shared-list-underline-item
  flex-col
  md:flex-row;
}

.ct-attributes-protected-area-source__item-title {
  @apply
  tw-shared-font-hind-siliguri__bold-base-grey-black
  md:w-[45%];
}

.ct-attributes-protected-area-source__item-date {
  @apply
  shrink-0
  tw-shared-list-stripes-value
  md:w-[15%];
}

.ct-attributes-protected-area-source__item-party {
  @apply
  tw-shared-list-stripes-value
  md:w-[40%];
}
</style>
