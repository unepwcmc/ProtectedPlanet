<template>
  <a
    class="card__link"
    :href="url"
    :title="title"
  >
    <div class="card__content">
      <h3
        class="card__title"
        v-html="title"
      />
      <p
        v-if="summary"
        class="card__summary"
        v-html="summary"
      />
    </div>

    <div class="card__image-placeholder">
      <div
        :alt="title"
        class="card__image"
        :style="{ backgroundImage: `url(${image})` }"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
import type { SearchSiteResult } from '@/types/backend'

type SearchSiteResultsItem = SearchSiteResult
defineProps<SearchSiteResultsItem>()
</script>
