<template>
  <div
    class="ct-map-toggler"
    tabindex="0"
    :class="{ 'ct-map-toggler--active': active }"
    @keyup.enter.stop.prevent="toggle()"
    @click.stop="toggle()"
  >
    <span
      class="ct-map-toggler__switch"
      v-text="actionText"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import useAnalytics from '@/composables/useAnalytics'

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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-toggler {
  @apply
  inline-flex
  items-center
  justify-start
  border
  border-theme-grey-xlight
  rounded-[0.875rem]
  cursor-pointer
  select-none
  p-0.5
  min-w-13.25
  h-6.75;
}

.ct-map-toggler__switch {
  @apply
  inline-flex
  items-center
  rounded-[0.875rem]
  bg-theme-grey
  text-theme-grey-xdark
  text-sm
  font-semibold
  ml-auto
  mr-0
  h-full
  pt-0.5
  px-1
  pb-0;
}

.ct-map-toggler--active {
  @apply justify-end;
}

.ct-map-toggler--active .ct-map-toggler__switch {
  @apply bg-theme-grey-xlight ml-0 mr-auto transition-all duration-100 ease-in-out;
}

/* The legacy `&:hover { &__switch {...} &__active {...} }` block is dropped,
   not ported — a genuine pre-existing Sass nesting bug (confirmed by
   compiling the source) concatenated `&__switch`/`&__active` directly onto
   `:hover` with no combinator, producing the invalid selectors
   `:hover__switch`/`:hover__active` that never matched anything in any
   browser. The toggler has never actually had a working hover state. */
</style>
