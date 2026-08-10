<template>
  <div class="card--message">
    <p
      class="card__warning"
      v-html="text"
    />
    <ul
      v-if="documents"
      class="list--links"
    >
      <li
        v-for="(document, i) in documents"
        :key="i"
        class="list__li"
      >
        <span v-text="document.name" />
        <a
          class="list__a"
          :class="document.type === 'pdf' ? 'ct-stats-message__link--pdf' : 'ct-stats-message__link--link'"
          :href="document.url"
          target="_blank"
          :title="document.name"
        >
          {{ document.button_text }}
          <IconDownload
            v-if="document.type === 'pdf'"
            class="ct-stats-message__link-icon--pdf"
          />
          <IconArrowExternal
            v-else
            class="ct-stats-message__link-icon--link"
          />
        </a>
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import type { StatsMessageProps } from '@/types/backend'
import IconDownload from '@/components/Icon/Download.vue'
import IconArrowExternal from '@/components/Icon/ArrowExternal.vue'

type StatsMessage = StatsMessageProps
defineProps<StatsMessage>()
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-stats-message__link--pdf {
  @apply
  inline-flex
  items-center
  text-theme-primary
  text-base
  font-bold;
}

.ct-stats-message__link-icon--pdf {
  @apply w-5 h-4.75 ml-2.5 text-theme-primary;
}

.ct-stats-message__link--link {
  @apply
  inline-flex
  items-center
  text-theme-primary
  text-base
  font-bold;
}

.ct-stats-message__link-icon--link {
  @apply w-6.25 h-3 text-theme-primary;
}
</style>
