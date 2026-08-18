<template>
  <div
    ref="rootEl"
    class="ct-search"
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
          'ct-search__wrapper--popout': popout,
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
          v-show="isSubmitVisible"
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
import usePopupCloseListeners from '@/composables/usePopupCloseListeners'

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

const isSubmitVisible = computed(() => props.popout || searchTerm.value.length !== 0)

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
@reference "#importtailwindcss";

.ct-search {
  @apply relative;
}

.ct-search__trigger {
  @apply flex
  size-8
  md:size-9
  lg:size-12
  shrink-0
  cursor-pointer
  items-center
  justify-center
  rounded-[3px]
  border-0
  bg-theme-primary
  p-0;
}

.ct-search__trigger-icon {
  @apply
  text-white
  size-3.75
  md:size-5.25;
}

.ct-search__pane {
  @apply
  w-full
  tw-shared-base-flex-gap-9;
}

.ct-search__pane--popout {
  @apply
  fixed
  inset-0
  z-20
  hidden
  h-screen
  w-full
  flex-col
  bg-white
  px-5
  pt-5
  md:inset-auto
  md:absolute
  md:top-0
  md:right-0
  md:h-auto
  md:w-150
  md:bg-transparent
  md:p-0;
}

.ct-search__pane--popout-active {
  @apply flex;
}

.ct-search__header {
  @apply
  flex
  justify-end
  items-center
  md:hidden;
}

.ct-search__close {
  @apply
  flex
  items-center
  justify-center;
}

.ct-search__close-icon {
  @apply
  size-5
  text-theme-grey-black;
}

.ct-search__wrapper {
  @apply
  w-full
  p-2
  md:px-4
  tw-shared-base-flex-gap-3
  items-center
  justify-between
  border-b
  h-12
  border-b-theme-grey
  md:rounded
  md:border
  md:border-theme-grey;
}

.ct-search__wrapper--popout {
  @apply bg-white;
}

.ct-search__wrapper--disabled {
   @apply
   bg-theme-grey/10
   text-theme-grey/10
   cursor-not-allowed
   pointer-events-none;
}

.ct-search__wrapper--disabled * {
   @apply cursor-not-allowed;
}

.ct-search__icon {
  @apply
  size-5.75
  text-theme-primary
  shrink-0;
}

.ct-search__input {
  @apply
  grow
  w-full
  border-none
  bg-transparent
  focus:outline-none;
}

.ct-search__submit {
  @apply
  shrink-0
  size-8.75
  flex
  justify-center
  items-center
  rounded
  bg-theme-primary
  disabled:bg-theme-grey/10 p-0;
}

.ct-search__submit-icon {
  @apply
  size-3.5
  -rotate-90
  text-white;
}
</style>
