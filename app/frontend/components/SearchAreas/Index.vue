<template>
  <SearchAreasInputAutocomplete
    :config
    :endpoint="endpointAutocomplete"
    @submit:search="updateSearchTerm"
  />
</template>

<script setup lang="ts">
import SearchAreasInputAutocomplete from '@/components/SearchAreas/InputAutocomplete.vue'
import type { SearchAreasProps } from '@/types/backend'

type SearchAreas = SearchAreasProps
const props = defineProps<SearchAreas>()

function updateSearchTerm(searchTerm: string) {
  window.location.href = props.endpointSearch.replace('SEARCHTERM', searchTerm)
}
</script>
