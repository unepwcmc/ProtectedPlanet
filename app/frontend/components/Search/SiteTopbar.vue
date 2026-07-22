<template>
  <SearchSiteInput
    :placeholder="placeholder"
    :popout="true"
    @submit:search="updateSearchTerm"
  />
</template>

<script setup lang="ts">
import SearchSiteInput from '@/components/Search/SiteInput.vue'

const props = defineProps<{
  endpoint: string
  placeholder: string
}>()

function updateSearchTerm(searchTerm: string) {
  window.location.href = props.endpoint + searchTerm
}
</script>
