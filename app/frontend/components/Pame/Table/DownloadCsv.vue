<template>
  <button
    class="button--download"
    :class="{ 'ct-pame-table-download-csv__button--disabled': isDisabled }"
    :disabled="isDisabled"
    title="Download CSV file of filtered protected area management effectiveness evaluations"
    @click="onDownload"
  >
    <span
      v-if="isDownloading"
      :class="['icon--loading-spinner', 'margin-center', { 'icon-visible': isDownloading }]"
    />
    <span v-else>CSV</span>
  </button>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useAnalytics } from '@/composables/useAnalytics'
import { postBlob } from '@/lib/http'
import { usePameStore } from '@/stores/usePameStore'

const { trackEvent } = useAnalytics()

const props = defineProps<{
  totalItems: number
}>()

const pameStore = usePameStore()
// Own flag for the spinner (this download specifically); `pameStore.isFetching`
// is the shared flag every PAME control disables against, so a table fetch or
// filter apply also disables this button, not just its own download.
const isDownloading = ref(false)

const hasNoResults = computed(() => props.totalItems === 0)
const isDisabled = computed(() => hasNoResults.value || pameStore.isFetching)

async function onDownload() {
  if (isDisabled.value) return

  isDownloading.value = true
  pameStore.setFetching(true)

  try {
    const { filename, blob } = await postBlob('/pame/download', { filters: pameStore.selectedFilterOptions })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')

    link.href = url
    link.download = filename
    link.click()
    window.URL.revokeObjectURL(url)

    trackEvent('click', { event_label: 'PAME - CSV download' })
  }
  catch (error) {
    console.error(error)
  }
  finally {
    isDownloading.value = false
    pameStore.setFetching(false)
  }
}
</script>
<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table-download-csv__button--disabled {
  @apply tw-shared-button--disabled;
}
</style>
