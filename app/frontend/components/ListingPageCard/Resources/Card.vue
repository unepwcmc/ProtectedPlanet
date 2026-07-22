<template>
  <div :class="['card', { 'card--link': props.url }]">
    <a
      v-if="props.url"
      class="card__link"
      :href="props.url"
      :title="props.title"
    >
      <p
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
    </a>
    <template v-else>
      <p
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
      <a
        v-if="props.fileUrl"
        class="button--download"
        :href="props.fileUrl"
        target="_blank"
        :title="props.title"
      />
      <a
        v-if="props.linkUrl"
        class="button--link-external"
        :href="props.linkUrl"
        target="_blank"
        :title="props.title"
        v-html="props.linkTitle"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import type { ListingPageCardResourcesProps } from '@/types/backend'

type ListingPageCardResources = ListingPageCardResourcesProps
const props = defineProps<ListingPageCardResources>()
</script>
