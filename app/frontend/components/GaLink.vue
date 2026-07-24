<template>
  <a
    :href
    @click="click"
    v-html="text"
  />
</template>

<script setup lang="ts">
import { trackEvent } from '@/lib/analytics'
import type { GaLinkProps } from '@/types/backend'

type GaLink = GaLinkProps
const props = defineProps<GaLink>()

function click() {
  if (props.gaId) {
    trackEvent('click', { event_label: `Link - ${props.gaId}` })
  }
}
</script>
