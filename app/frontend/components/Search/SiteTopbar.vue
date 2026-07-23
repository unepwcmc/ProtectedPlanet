<template>
  <SearchSiteInput
    :placeholder="placeholder"
    :popout="true"
    @submit:search="updateSearchTerm"
  />
</template>

<script setup lang="ts">
import SearchSiteInput from '@/components/Search/SiteInput.vue'
import type { SearchSiteTopbarProps } from '@/types/backend'

type SearchSiteTopbar = SearchSiteTopbarProps
const props = defineProps<SearchSiteTopbar>()

function updateSearchTerm(searchTerm: string) {
  window.location.href = props.endpoint + searchTerm
}
</script>
