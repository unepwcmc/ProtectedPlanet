<template>
  <div
    ref="rootEl"
    class="ct-tooltip"
    :class="{ 'ct-tooltip--active': isActive }"
  >
    <button
      v-if="onHover"
      type="button"
      :aria-describedby="id"
      :aria-expanded="isActive"
      :aria-label="triggerLabel"
      class="ct-tooltip__trigger"
      @mouseenter="toggleTooltip(true)"
      @mouseleave="toggleTooltip(false)"
      @focus="toggleTooltip(true)"
      @blur="toggleTooltip(false)"
      @touchend.prevent="toggleTooltip()"
    >
      <slot />
    </button>
    <button
      v-else
      type="button"
      :aria-describedby="id"
      :aria-expanded="isActive"
      :aria-label="triggerLabel"
      class="ct-tooltip__trigger"
      @click="toggleTooltip()"
    >
      <slot />
    </button>

    <div
      v-show="isActive"
      :id
      role="tooltip"
      class="ct-tooltip__target"
    >
      <button
        v-if="!onHover"
        class="ct-tooltip__close"
        aria-label="Close tooltip"
        @click="toggleTooltip(false)"
      >
        <span aria-hidden="true">&times;</span>
      </button>

      <div v-html="text" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, useId, useSlots } from 'vue'
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'

interface TooltipProps {
  text: string
  onHover?: boolean
  // Only needed when the default slot is empty (the icon-only case); a filled
  // slot names the trigger by its own content.
  triggerLabel?: string
}

const props = withDefaults(defineProps<TooltipProps>(), { onHover: true, triggerLabel: undefined })

const slots = useSlots()

// An aria-label would shadow slot content, so it is only applied when there is
// none to shadow.
const triggerLabel = computed(() => props.triggerLabel ?? (slots.default ? undefined : 'More information'))

const id = `tooltip_${useId()}`
const isActive = ref(false)
const rootEl = ref<HTMLElement | null>(null)

function toggleTooltip(value?: boolean) {
  isActive.value = typeof value === 'boolean' ? value : !isActive.value
}

usePopupCloseListeners(rootEl, {
  isActive,
  onClose: () => toggleTooltip(false)
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-tooltip {
  @apply relative inline-block;
}

.ct-tooltip__trigger {
  @apply cursor-pointer;
}

.ct-tooltip__target {
  @apply absolute z-10 rounded bg-theme-grey-black p-2 text-sm text-white;
}

.ct-tooltip__close {
  @apply absolute right-1 top-1 h-4 w-4 border-none bg-none bg-transparent p-0 leading-none text-white;
}
</style>
