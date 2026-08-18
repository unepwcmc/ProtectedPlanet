<template>
  <li
    v-if="hasOptions"
    class="ct-pame-filter"
  >
    <button
      class="ct-pame-filter__button"
      :class="{
        'ct-pame-filter__button--active': isOpen,
        'ct-pame-filter__button--has-selected': hasSelected,
        'ct-pame-filter__button--disabled': isFetching
      }"
      @click="onToggle"
    >
      <span
        class="ct-pame-filter__title"
        :class="{
          'ct-pame-filter__title--active': isOpen
        }"
        v-text="title"
      />
      <IconArrow
        v-if="!hasSelected"
        class="ct-pame-filter__icon"
        :class="{ 'ct-pame-filter__icon--active': isOpen }"
      />
      <span
        v-show="hasSelected"
        class="ct-pame-filter__button-total"
        v-text="appliedOptions.length"
      />
    </button>
    <template v-if="isOpen">
      <PameFiltersFilterMobile
        v-if="isSmall || isMedium"
        :name
        :title
        :options
        :appliedOptions
        :isFetching
        :isOpen
        @toggle="emit('toggle')"
        @apply="emit('apply',$event)"
      />
      <PameFiltersFilterDesktop
        v-else
        :name
        :title
        :options
        :appliedOptions
        :isFetching
        :isOpen
        @toggle="emit('toggle')"
        @apply="emit('apply',$event)"
      />
    </template>
  </li>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import IconArrow from '@/components/Icon/Arrow.vue'
import PameFiltersFilterMobile from '@/components/Pame/Filters/Filter/Mobile.vue'
import PameFiltersFilterDesktop from '@/components/Pame/Filters/Filter/Desktop.vue'
import useBreakpoint from '@/composables/useBreakpoint'

const props = defineProps<{
  name: string
  title: string
  options: string[]
  appliedOptions: string[]
  isFetching: boolean
  isOpen: boolean
}>()

const emit = defineEmits<{
  toggle: []
  apply: [options: string[]]
}>()

const { isSmall, isMedium } = useBreakpoint()

const hasOptions = computed(() => props.options.length > 0)
const hasSelected = computed(() => props.appliedOptions.length > 0)

function onToggle() {
  if (props.isFetching) return
  emit('toggle')
}

</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-filter {
  @apply relative;
}

.ct-pame-filter__button {
  @apply
  tw-shared-button-basic
  relative
  tw-shared-base-flex-gap-2
  items-center
  cursor-pointer
  rounded-[0.1875rem]
  border
  border-black
  text-black
  h-8.5
  px-2.75
  text-base
  lg:h-14
  lg:px-6.75
  lg:text-lg
  hover:bg-theme-primary
  hover:border-theme-primary
  hover:text-white;
}

.ct-pame-filter__button--active {
  @apply
  bg-theme-primary
  border-theme-primary
  text-white;
}

.ct-pame-filter__title {
  @apply tw-shared-font-hind-siliguri__light-base-md-lg-grey-black;
}

.ct-pame-filter__title--active {
  @apply text-white;
}

.ct-pame-filter__icon {
  @apply
  invisible
  lg:visible
  size-2;
}

.ct-pame-filter__icon--active {
  @apply rotate-180;
}

.ct-pame-filter__button--has-selected {
  @apply
  bg-theme-primary
  border-theme-primary
  text-white;
}

.ct-pame-filter__button--disabled {
  @apply tw-shared-button--disabled;
}

.ct-pame-filter__button-total {
  @apply
  flex
  items-center
  justify-center
  rounded-full
  bg-white
  tw-shared-font-hind-siliguri__light-sm-lg-lg-primary
  size-5
  lg:size-6;
}
</style>
