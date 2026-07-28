<template>
  <div class="card--stats-source">
    <h2
      v-if="title"
      class="card__h2"
      v-text="title"
    />
    <div class="card__content flex">
      <ol class="list--underline-sources">
        <li
          v-for="(source, index) in sourceAttributes"
          :key="`${index}sourceAttributes`"
          class="list__li"
        >
          <span
            class="list__title"
            v-text="source.title"
          />
          <span
            class="list__date"
            v-text="`${translations.updated}: ${source.date_updated}`"
          />
          <span
            class="list__party"
            v-text="source.resp_party"
          />
        </li>
      </ol>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { AttributesProtectedAreaSourcesTranslations, StatsSourceItem } from '@/types/backend'

defineProps<{
  title?: string
  sourceAttributes: StatsSourceItem[]
  translations: AttributesProtectedAreaSourcesTranslations
}>()
</script>
