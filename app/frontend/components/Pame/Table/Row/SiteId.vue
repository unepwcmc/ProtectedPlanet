<template>
  <span class="ct-pame-table-row-site-id">
    <span class="ct-pame-table-row-site-id__site-id">{{ siteId }}</span>
    <span
      v-if="hasParcelId"
      class="ct-pame-table-row-site-id__site-pid"
    >
      <span class="ct-pame-table-row-site-id__site-pid-label">/</span>
      <span>{{ sitePid }}</span>
    </span>
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  siteId: number | null
  sitePid: string | null
}>()

const hasParcelId = computed(() => String(props.sitePid) !== String(props.siteId))
</script>
