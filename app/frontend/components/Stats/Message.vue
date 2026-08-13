<template>
  <div class="ct-stats-message">
    <p
      class="ct-stats-message__warning"
    >
      <span
        class="ct-stats-message__warning-disclaimer"
        v-text="'Disclaimer:'"
      />
      <span
        class="ct-stats-message__warning-text"
        v-text="text"
      />
    </p>
    <ul
      v-if="documents"
      class="ct-stats-message__list"
    >
      <li
        v-for="(document, i) in documents"
        :key="i"
        class="ct-stats-message__item"
      >
        <span
          class="ct-stats-message__file-name"
          v-text="document.name"
        />
        <a
          class="ct-stats-message__link"
          :class="document.type === 'pdf' ? 'ct-stats-message__link--pdf' : 'ct-stats-message__link--link'"
          :href="document.url"
          target="_blank"
          :title="document.name"
        >
          <span
            class="ct-stats-message__text"
            v-text="document.button_text"
          />
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

.ct-stats-message {
  @apply tw-shared-messages__container;
}

.ct-stats-message__warning-disclaimer {
  @apply
  tw-shared-font-hind-siliguri__semibold-xl-grey-black
  mr-1;
}

.ct-stats-message__warning-text {
  @apply tw-shared-messages__text;
}

.ct-stats-message__list {
  @apply tw-shared-list-links;
}

.ct-stats-message__item {
  @apply tw-shared-list-links-item;
}

.ct-stats-message__file-name{
  @apply tw-shared-font-hind-siliguri__light-lg-grey-black;
}

.ct-stats-message__link {
  @apply
  tw-shared-base-flex-gap-1
  items-center
  tw-shared-font-hind-siliguri__semibold-lg-primary;
}

.ct-stats-message__link-icon--pdf {
  @apply
  w-5
  h-4.75
  text-theme-primary;
}

.ct-stats-message__link-icon--link {
  @apply
  w-6.25
  h-3
  text-theme-primary;
}
</style>
