<template>
  <th class="table-head__cell">
    <span
      class="table-head__title"
      v-text="filter.title"
    />

    <Tooltip
      v-if="hasTooltip"
      :text="filter.tooltip ?? ''"
    />

    <div
      v-if="hasOptions"
      class="table__sorting"
    >
      <span
        alt="Sort results"
        class="table__sort table__sort--ascending"
      />
      <span
        alt="Sort results"
        class="table__sort table__sort--descending"
      />
    </div>
  </th>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import Tooltip from '@/components/Tooltip/Index.vue'
import type { PameTableAttribute } from '@/types/backend'

const props = defineProps<{
  filter: PameTableAttribute
}>()

// `field` stands in for the legacy `name`/`options` presence check — every
// TABLE_ATTRIBUTES entry has one, so every column shows the sort icons (a
// purely visual/legacy holdover — see the note below).
const hasOptions = computed(() => props.filter.field !== undefined)
const hasTooltip = computed(() => !!props.filter.tooltip)
</script>
