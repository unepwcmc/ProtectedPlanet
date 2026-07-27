<template>
  <a
    class="card"
    :href="url"
  >
    <div
      v-if="image"
      class="card__image"
      :style="{ backgroundImage: `url(${image})` }"
    />
    <div
      v-else
      class="card__image"
    >
      <i class="card__icon icon--image" />
    </div>

    <div class="card__content">
      <p
        v-if="date"
        class="card__date"
        v-html="date"
      />
      <h3
        class="card__h3"
        v-html="title"
      />
      <p
        class="card__summary"
        v-html="summary"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
import type { ListingPageCardNewsProps } from '@/types/backend'

type ListingPageCardNews = ListingPageCardNewsProps
defineProps<ListingPageCardNews>()
</script>
