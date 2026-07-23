<template>
  <a
    class="card"
    :href="props.url"
  >
    <div
      v-if="props.image"
      class="card__image"
      :style="{ backgroundImage: `url(${props.image})` }"
    />
    <div
      v-else
      class="card__image"
    >
      <i class="card__icon icon--image" />
    </div>

    <div class="card__content">
      <p
        v-if="props.date"
        class="card__date"
        v-html="props.date"
      />
      <h3
        class="card__h3"
        v-html="props.title"
      />
      <p
        class="card__summary"
        v-html="props.summary"
      />
    </div>
  </a>
</template>

<script setup lang="ts">
import type { ListingPageCardNewsProps } from '@/types/backend'

type ListingPageCardNews = ListingPageCardNewsProps
const props = defineProps<ListingPageCardNews>()
</script>
