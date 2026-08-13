<template>
  <th class="ct-pame-table-head__cell">
    <span
      class="ct-pame-table-head__title"
      v-text="filter.title"
    />
    <Tooltip
      v-if="hasTooltip"
      :text="filter.tooltip ?? ''"
    />
  </th>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import Tooltip from '@/components/Tooltip/Index.vue'
import type { PameTableAttribute } from '@/types/backend'

const props = defineProps<{
  filter: PameTableAttribute
}>()

const hasTooltip = computed(() => !!props.filter.tooltip)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table-head__cell {
  @apply
  border-l-2
  border-dotted
  border-white
  first:border-l-0
  bg-black
  pt-2
  px-3.5
  h-14.25
  text-left
  tw-shared-font-hind-siliguri__semibold-lg-white
  align-top;
}

.ct-pame-table-head__title {
  @apply
  inline-block
  align-middle;
}
</style>
