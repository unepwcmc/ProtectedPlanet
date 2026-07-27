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
          :class="`button--${document.type}`"
          :href="document.url"
          target="_blank"
          :title="document.name"
          v-text="document.button_text"
        />
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import type { StatsMessageProps } from '@/types/backend'

type StatsMessage = StatsMessageProps
defineProps<StatsMessage>()
</script>
