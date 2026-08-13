<template>
  <div
    ref="rootEl"
    class="ct-tooltip-second"
    :class="{ 'ct-tooltip-second--active': isActive }"
  >
    <button
      v-if="onHover"
      ref="triggerEl"
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
      ref="triggerEl"
      tabindex="0"
      :aria-describedby="id"
      :aria-expanded="isActive"
      class="ct-tooltip-second__trigger"
      @click="toggleTooltip()"
    >
      <slot name="trigger" />
    </div>
    <div
      v-if="isActive"
      :id
      ref="targetEl"
      role="tooltip"
      class="ct-tooltip-second__target"
      :style="{ '--ct-tooltip-second-shift': `${shiftX}px` }"
    >
      <div class="ct-tooltip-second__header">
        <slot name="header" />
        <button
          v-if="!onHover"
          class="ct-tooltip-second__close"
          aria-label="Close tooltip"
          @click="toggleTooltip(false)"
        >
          <IconClose
            class="ct-tooltip-second__close-icon"
            aria-hidden="true"
          />
        </button>
      </div>
      <slot name="content" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, useId, nextTick } from 'vue'
import { useEventListener } from '@vueuse/core'
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'
import IconClose from '@/components/Icon/Close.vue'

interface TooltipSecondProps {
  onHover?: boolean
}

withDefaults(defineProps<TooltipSecondProps>(), { onHover: true })

const VIEWPORT_MARGIN_PX = 8

const id = `tooltip_${useId()}`
const isActive = ref(false)
const rootEl = ref<HTMLElement | null>(null)
const triggerEl = ref<HTMLElement | null>(null)
const targetEl = ref<HTMLElement | null>(null)
const shiftX = ref(0)

function toggleTooltip(value?: boolean) {
  isActive.value = typeof value === 'boolean' ? value : !isActive.value
  if (isActive.value) nextTick(updateShift)
}

// The target is centered on the trigger by default (see CSS). If that would
// push it past the viewport edge, shift the box (not the arrow, which stays
// pinned to the trigger) just enough to keep it fully on screen.
function updateShift() {
  if (!triggerEl.value || !targetEl.value) return

  const triggerRect = triggerEl.value.getBoundingClientRect()
  const targetWidth = targetEl.value.offsetWidth
  const centerX = triggerRect.left + triggerRect.width / 2
  const naturalLeft = centerX - targetWidth / 2
  const naturalRight = centerX + targetWidth / 2
  const viewportWidth = window.innerWidth

  if (naturalLeft < VIEWPORT_MARGIN_PX) {
    shiftX.value = VIEWPORT_MARGIN_PX - naturalLeft
  }
  else if (naturalRight > viewportWidth - VIEWPORT_MARGIN_PX) {
    shiftX.value = viewportWidth - VIEWPORT_MARGIN_PX - naturalRight
  }
  else {
    shiftX.value = 0
  }
}

useEventListener(window, 'resize', () => {
  if (isActive.value) updateShift()
})

usePopupCloseListeners(rootEl, {
  isActive,
  onClose: () => toggleTooltip(false)
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-tooltip-second {
  @apply relative;
}

.ct-tooltip-second__trigger {
  @apply
  cursor-pointer
  border-none
  bg-none
  bg-transparent
  p-0;
}

.ct-tooltip-second__target {
  @apply
  absolute
  top-full
  left-1/2
  z-10
  mt-2
  rounded
  bg-white
  p-3
  shadow-lg
  tw-shared-base-flex-col-gap-2
  before:absolute
  before:-top-2
  before:h-0
  before:w-0
  before:border-x-8
  before:border-b-8
  before:border-x-transparent
  before:border-b-white
  before:content-[''];

  transform: translateX(calc(-50% + var(--ct-tooltip-second-shift, 0px)));
}

.ct-tooltip-second__target::before {
  left: calc(50% - var(--ct-tooltip-second-shift, 0px));
  transform: translateX(-50%);
}

.ct-tooltip-second__header {
  @apply
  flex
  items-center
  justify-end;
}

.ct-tooltip-second__close-icon {
  @apply size-3;
}
</style>
