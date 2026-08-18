<template>
  <a
    :href
    @click="click"
    v-html="text"
  />
</template>

<script setup lang="ts">
import useAnalytics from '@/composables/useAnalytics'
import type { GaLinkProps } from '@/types/backend'

const { trackEvent } = useAnalytics()

type GaLink = GaLinkProps
const props = defineProps<GaLink>()

function click() {
  if (props.gaId) {
    trackEvent('click', { event_label: `Link - ${props.gaId}` })
  }
}
</script>
