<template>
  <div>
    <h3
      v-if="title"
      class="card__h3"
      v-text="title"
    />
    <ul
      v-if="Object.keys(pameAttributes).length > 0"
      class="list--stripes"
    >
      <li
        v-for="(years, methodology) in pameAttributes"
        :key="methodology"
        class="list__li"
      >
        <span
          class="list__title"
          v-text="methodology"
        />
        <span
          class="list__value"
          v-text="years.join(', ')"
        />
      </li>
    </ul>
    <p
      v-else
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
}>()
</script>
