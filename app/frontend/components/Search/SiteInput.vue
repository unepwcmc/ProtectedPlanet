<template>
  <div
    ref="rootEl"
    class="ct-search ct-search--main"
    :disabled
  >
    <button
      v-if="popout"
      class="ct-search__trigger"
      @click="toggleInput"
    >
      <IconSearch class="ct-search__trigger-icon" />
    </button>
    <div
      class="ct-search__pane"
      :class="{
        'ct-search__pane--popout-active': isActive,
        'ct-search__pane--popout': popout
      }"
    >
      <div
        v-if="popout"
        class="ct-search__header"
      >
        <button
          class="ct-search__close"
          aria-label="Close search"
          @click="closeInput"
        >
          <IconClose class="ct-search__close-icon" />
        </button>
      </div>
      <div
        class="ct-search__wrapper"
        :class="{
          'ct-search__wrapper--popout':popout,
          'ct-search__wrapper--disabled': disabled
        }"
      >
        <IconSearch class="ct-search__icon" />
        <input
          ref="inputEl"
          v-model="searchTerm"
          type="text"
          name="ct-search__input"
          class="ct-search__input"
          :disabled
          :placeholder
          @keyup.enter="submit"
        >
        <button
          v-show="showSubmit"
          class="ct-search__submit"
          :disabled
          @click="submit"
        >
          <IconArrow class="ct-search__submit-icon" />
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import IconArrow from '@/components/Icon/Arrow.vue'
import IconClose from '@/components/Icon/Close.vue'
import IconSearch from '@/components/Icon/Search.vue'
import { usePopupCloseListeners } from '@/composables/usePopupCloseListeners'

const props = defineProps<{
  disabled?: boolean
  placeholder: string
  popout?: boolean
  prePopulatedSearchTerm?: string
}>()

const emit = defineEmits<{ 'submit:search': [searchTerm: string] }>()

const isActive = ref(!props.popout)
const searchTerm = ref(props.prePopulatedSearchTerm ?? '')
const inputEl = ref<HTMLInputElement | null>(null)
const rootEl = ref<HTMLElement | null>(null)

const showSubmit = computed(() => props.popout || searchTerm.value.length !== 0)

if (props.popout) {
  usePopupCloseListeners(rootEl, { isActive, onClose: closeInput })
}

function closeInput() {
  isActive.value = false
}

function submit() {
  if (props.disabled) return
  emit('submit:search', searchTerm.value)
}

function toggleInput() {
  isActive.value = !isActive.value
  // Matches the legacy component's own setTimeout(0): waits a macrotask past
  // Vue's render flush so the popout pane's CSS transition has started before
  // focusing, not just nextTick's "DOM updated" point.
  setTimeout(() => inputEl.value?.focus(), 0)
}
</script>

<style scoped lang="css">
@reference "tailwindcss";

.ct-search--main {
  @apply relative;
}

.ct-search__trigger {
  @apply flex size-8.75 shrink-0 cursor-pointer items-center justify-center rounded-[3px] border-0 bg-theme-primary p-0 md:size-11.75;
}

.ct-search__trigger-icon {
  @apply size-3.75 text-white md:h-5.75 md:w-5.25;
}

.ct-search__pane {
  @apply w-full;
}

.ct-search__pane--popout {
  @apply fixed inset-0 z-20 hidden h-screen w-full flex-col bg-white px-5 pt-5 md:inset-auto md:absolute md:top-0 md:right-0 md:h-auto md:w-150 md:bg-transparent md:p-0;
}

.ct-search__pane--popout-active {
  @apply flex;
}

.ct-search__header {
  @apply mb-6 flex justify-end md:hidden;
}

.ct-search__close {
  @apply flex size-9 cursor-pointer items-center justify-center rounded-[3px] border-0 bg-transparent p-0;
}

.ct-search__close-icon {
  @apply size-4 text-theme-grey-black;
}

.ct-search__wrapper {
  @apply w-full p-1 md:px-3 flex gap-1 items-center justify-between border-b border-b-black md:rounded md:border md:border-black;
}

.ct-search__wrapper--popout {
  @apply bg-white;
}

.ct-search__wrapper--disabled {
   @apply bg-theme-grey/10 text-theme-grey/10 cursor-not-allowed pointer-events-none;
}

.ct-search__wrapper--disabled * {
   @apply cursor-not-allowed;
}

.ct-search__icon {
  @apply h-5.75 w-5.25 text-theme-primary;
}

.ct-search__input {
  @apply grow w-full border-none bg-transparent;
}

.ct-search__submit {
  @apply size-8.75 flex justify-center items-center rounded border-0 bg-theme-primary disabled:bg-theme-grey/10 p-0;
}

.ct-search__submit-icon {
  @apply h-2.5 w-3.5 -rotate-90 text-white;
}
</style>
