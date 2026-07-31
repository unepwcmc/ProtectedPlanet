<template>
  <div
    class="v-map-toggler"
    tabindex="0"
    :class="{ 'v-map-toggler--active': active }"
    @keyup.enter.stop.prevent="toggle()"
    @click.stop="toggle()"
  >
    <span
      class="v-map-toggler__switch"
      v-text="actionText"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useAnalytics } from '@/composables/useAnalytics'

const { trackEvent } = useAnalytics()

const props = withDefaults(defineProps<{
  active: boolean
  gaId?: string
  onText?: string
  offText?: string
}>(), {
  gaId: undefined,
  onText: 'ON',
  offText: 'OFF'
})

const emit = defineEmits<{ change: [active: boolean] }>()

const actionText = computed(() => (props.active ? props.onText : props.offText))

function toggle(newState?: boolean) {
  const newBoolean = typeof newState === 'boolean' ? newState : !props.active

  emit('change', newBoolean)

  if (props.gaId) {
    trackEvent('click', { event_label: `${props.gaId} - Toggle map layer: ${newBoolean}` })
  }
}
</script>
