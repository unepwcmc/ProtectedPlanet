<template>
  <div class="ct-map-header">
    <span
      class="ct-map-header__title"
      v-text="title"
    />
    <div
      v-if="closeable"
      class="ct-map-header__close"
      role="button"
      tabindex="0"
      :aria-label="filtersShown ? 'Close panel' : 'Expand panel'"
      :aria-expanded="filtersShown"
      @click="toggle"
      @keydown.enter.prevent="toggle"
      @keydown.space.prevent="toggle"
    >
      <IconClose
        v-if="filtersShown"
        class="ct-map-header__close-icon"
      />
      <IconMinus
        v-else
        class="ct-map-header__close-icon"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import IconClose from '@/components/Icon/Close.vue'
import IconMinus from '@/components/Icon/Minus.vue'

withDefaults(defineProps<{
  title: string
  closeable?: boolean
  filtersShown?: boolean
}>(), {
  closeable: false,
  filtersShown: true
})

const emit = defineEmits<{ toggle: [] }>()

const toggle = () => emit('toggle')
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-map-header {
  @apply
  tw-shared-base-flex-gap-3
  justify-between
  items-center
  bg-theme-grey-black
  py-3.5
  px-6;
}

.ct-map-header__title {
  @apply tw-shared-font-playfair__semi-bold-xl-md-2xl-grey-xlight;
}

.ct-map-header__close-icon {
  @apply
  cursor-pointer
  size-5
  text-white;
}
</style>
