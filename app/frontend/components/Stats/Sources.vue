<template>
  <div class="card--feault-block sm-sources pdf-break-inside-avoid">
    <h2 v-text="`${title} ${count}`" />

    <div class="card__content flex">
      <ol class="list--underline-sources">
        <li
          v-for="(source, i) in sources"
          :key="i"
          class="list__li"
        >
          <span
            class="list__title"
            v-text="source.title"
          />
          <span
            class="list__date"
            v-text="`${sourceUpdated}: ${source.date_updated}`"
          />
          <span
            class="list__party"
            v-text="source.resp_party"
          />
        </li>
      </ol>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { StatsSourcesProps } from '@/types/backend'

type StatsSources = StatsSourcesProps
defineProps<StatsSources>()
</script>
