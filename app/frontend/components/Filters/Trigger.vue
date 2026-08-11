<template>
  <button
    class="ct-filters-trigger"
    :class="{ 'ct-filters-trigger--disabled': isDisabled }"
    @click="toggleFilterPane"
  >
    <span
      class="ct-filters-trigger__text"
      v-text="text"
    />
    <IconFilters class="ct-filters-trigger__icon" />
  </button>
</template>

<script setup lang="ts">
import IconFilters from '@/components/Icon/Filters.vue'

const props = withDefaults(defineProps<{
  isDisabled?: boolean
  text: string
}>(), {
  isDisabled: false
})

const emit = defineEmits<{ 'toggle:filterPane': [] }>()

function toggleFilterPane() {
  if (props.isDisabled) return
  emit('toggle:filterPane')
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-filters-trigger {
  @apply
  tw-shared-base-flex-gap-3
  tw-shared-button--outline-black
  p-3
  md:px-6;
}

.ct-filters-trigger--disabled {
  @apply tw-shared-button--disabled;
}

.ct-filters-trigger__text {
  @apply
  hidden
  md:inline
  tw-shared-font-hind-siliguri__light-lg-grey-black;
}

.ct-filters-trigger__icon {
  @apply
  size-4
  text-theme-primary;
}
</style>
