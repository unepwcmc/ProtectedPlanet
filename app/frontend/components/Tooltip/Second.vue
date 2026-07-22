<template>
  <div
    ref="rootEl"
    class="ct-tooltip-second"
    :class="{ 'ct-tooltip-second--active': isActive }"
  >
    <button
      v-if="onHover"
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="ct-tooltip-second__trigger"
      @mouseenter="toggleTooltip(true)"
      @mouseleave="toggleTooltip(false)"
      @focus="toggleTooltip(true)"
      @blur="toggleTooltip(false)"
      @touchend.prevent="toggleTooltip()"
    >
      <slot name="trigger" />
    </button>
    <div
      v-else
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="ct-tooltip-second__trigger"
      @click="toggleTooltip()"
    >
      <slot name="trigger" />
    </div>

    <div
      v-show="isActive"
      :id="id"
      role="tooltip"
      class="ct-tooltip-second__target"
    >
      <div class="ct-tooltip-second__header">
        <slot name="header" />
        <button
          v-if="!onHover"
          class="ct-tooltip-second__close"
          aria-label="Close tooltip"
          @click="toggleTooltip(false)"
        >
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <slot name="content" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, useId } from 'vue'
import { usePopupCloseListeners } from '@/composables/usePopupCloseListeners'

interface TooltipSecondProps {
  onHover?: boolean
}

withDefaults(defineProps<TooltipSecondProps>(), { onHover: true })

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

.ct-tooltip-second {
  @apply relative inline-block;
}

.ct-tooltip-second__trigger {
  @apply cursor-pointer border-none bg-none bg-transparent p-0;
}

.ct-tooltip-second__target {
  @apply absolute z-10 rounded bg-white p-3 text-sm text-theme-grey-black shadow-lg;
}

.ct-tooltip-second__header {
  @apply flex items-center justify-between;
}

.ct-tooltip-second__close {
  @apply h-4 w-4 border-none bg-none bg-transparent p-0 leading-none text-theme-grey-black;
}
</style>
