<template>
  <ul class="ct-pame-filter-options__list">
    <PameFiltersFilterOption
      v-for="option in options"
      :key="option"
      :option
      :checked="selectedOptions.includes(option)"
      :groupId
      @click="onOptionClick(option, $event)"
    />
  </ul>
</template>

<script setup lang="ts">
import PameFiltersFilterOption from '@/components/Pame/Filters/Filter/Option.vue'

defineProps<{
  options: string[]
  selectedOptions: string[]
  groupId: string
}>()

const emit = defineEmits<{ click: [option: string, checked: boolean] }>()

function onOptionClick(option: string, checked: boolean) {
  emit('click', option, checked)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-filter-options__list {
  @apply
  list-none
  max-h-[85vh]
  overflow-y-scroll
  overflow-x-hidden
  lg:max-h-90
  tw-shared-base-flex-col;
}
</style>
