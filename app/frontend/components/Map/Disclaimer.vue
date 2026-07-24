<template>
  <div
    v-if="disclaimer"
    class="v-map-disclaimer"
  >
    <span
      class="v-map-disclaimer__heading"
      v-text="disclaimer.heading"
    />
    <div
      class="v-map-disclaimer__body"
      v-html="disclaimer.body"
    />
  </div>
</template>

<script setup lang="ts">
import type { MapDisclaimerProps } from '@/types/backend'

type MapDisclaimer = MapDisclaimerProps
withDefaults(defineProps<MapDisclaimer>(), {
  disclaimer: null
})
</script>
