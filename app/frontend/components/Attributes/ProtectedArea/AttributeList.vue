<template>
  <ul
    v-if="attributes.length > 0"
    class="ct-attributes-protected-area-list"
  >
    <template
      v-for="(attribute, index) in attributes"
      :key="`${index}parcelattribute`"
    >
      <li
        v-if="forPdf || !attribute.is_site_pid"
        class="ct-attributes-protected-area-list__item
        tw-global-pdf-export__break-inside-avoid"
        :class="{
          'ct-attributes-protected-area-list__item--for-pdf': forPdf
        }"
      >
        <span
          class="ct-attributes-protected-area-list__item-title"
          v-text="attribute.title"
        />
        <!-- Trusted server-rendered value (ProtectedAreaPresenter), not user input. -->
        <span
          class="ct-attributes-protected-area-list__item-value"
          v-html="attribute.value"
        />
      </li>
    </template>
  </ul>
</template>

<script setup lang="ts">
import type { AttributesAttributeItem } from '@/types/backend'

defineProps<{
  attributes: AttributesAttributeItem[]
  forPdf: boolean
}>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-attributes-protected-area-list {
  @apply tw-shared-base-flex-col;
}

.ct-attributes-protected-area-list__item {
  @apply tw-shared-list-stripes-item;
}

.ct-attributes-protected-area-list__item--for-pdf {
  @apply tw-shared-list-stripes-item-for-pdf;
}

.ct-attributes-protected-area-list__item-title {
  @apply tw-shared-list-stripes-title;
}

.ct-attributes-protected-area-list__item-value {
  @apply tw-shared-list-stripes-value;
}
</style>
