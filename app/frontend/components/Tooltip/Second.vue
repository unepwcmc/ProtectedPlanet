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
      v-if="isActive"
      :id
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
import { ref, useId } from 'vue'
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'
import IconClose from '@/components/Icon/Close.vue'

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
  -translate-x-1/2
  rounded
  bg-white
  p-3
  shadow-lg
  tw-shared-base-flex-col-gap-2
  before:absolute
  before:-top-2
  before:left-1/2
  before:h-0
  before:w-0
  before:-translate-x-1/2
  before:border-x-8
  before:border-b-8
  before:border-x-transparent
  before:border-b-white
  before:content-[''];
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
