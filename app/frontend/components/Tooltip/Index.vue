<template>
  <div
    ref="rootEl"
    class="ct-tooltip"
    :class="{ 'ct-tooltip--active': isActive }"
  >
    <div
      v-if="onHover"
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="ct-tooltip__trigger"
      @mouseenter="toggleTooltip(true)"
      @mouseleave="toggleTooltip(false)"
      @focus="toggleTooltip(true)"
      @blur="toggleTooltip(false)"
      @touchend.prevent="toggleTooltip()"
    >
      <slot />
    </div>
    <div
      v-else
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="ct-tooltip__trigger"
      @click="toggleTooltip()"
    >
      <slot />
    </div>

    <div
      v-show="isActive"
      :id="id"
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
import { ref, useId } from 'vue'
import { usePopupCloseListeners } from '@/composables/usePopupCloseListeners'

interface TooltipProps {
  text: string
  onHover?: boolean
}

withDefaults(defineProps<TooltipProps>(), { onHover: true })

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
@reference "tailwindcss";

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
