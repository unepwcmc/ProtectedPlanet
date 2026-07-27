<template>
  <SearchAreasInputAutocomplete
    :config
    :endpoint="endpointAutocomplete"
    @submit:search="updateSearchTerm"
  />
</template>

<script setup lang="ts">
import SearchAreasInputAutocomplete from '@/components/SearchAreas/InputAutocomplete.vue'
import type { SearchAreasHomeProps } from '@/types/backend'

type SearchAreasHome = SearchAreasHomeProps
const props = defineProps<SearchAreasHome>()

function updateSearchTerm(searchTerm: string) {
  window.location.href = props.endpointSearch.replace('SEARCHTERM', searchTerm)
}
</script>
