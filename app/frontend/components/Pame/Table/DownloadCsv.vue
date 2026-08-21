<template>
  <button
    class="ct-pame-table-download-csv__button"
    :class="{ 'ct-pame-table-download-csv__button--disabled': isDisabled }"
    :disabled="isDisabled"
    title="Download CSV file of filtered protected area management effectiveness evaluations"
    @click="onDownload"
  >
    <span
      v-if="isDownloading"
      class="ct-pame-table-download-csv__spinner"
    />
    <span v-else>CSV</span>
    <IconDownload class="ct-pame-table-download-csv__button-icon" />
  </button>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import useAnalytics from '@/composables/useAnalytics'
import { postBlob } from '@/lib/http'
import IconDownload from '@/components/Icon/Download.vue'
import type { PameFilterSelection } from '@/types/backend'

const { trackEvent } = useAnalytics()

const props = defineProps<{
  isFetching: boolean
  selectedFilterOptions: PameFilterSelection[]
  totalItems: number
}>()

const emit = defineEmits<{ 'update:isFetching': [value: boolean] }>()

// Own flag for the spinner; `isFetching` is the shared one, so a table fetch or
// filter apply disables this button too.
const isDownloading = ref(false)

const hasNoResults = computed(() => props.totalItems === 0)
const isDisabled = computed(() => hasNoResults.value || props.isFetching)

async function onDownload() {
  if (isDisabled.value) return

  isDownloading.value = true
  emit('update:isFetching', true)

  try {
    const { filename, blob } = await postBlob('/pame/download', { filters: props.selectedFilterOptions })
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
    emit('update:isFetching', false)
  }
}
</script>
<style scoped lang="css">
@reference "#importtailwindcss";

.ct-pame-table-download-csv__button {
  @apply tw-shared-button--download;
}

.ct-pame-table-download-csv__button-icon {
  @apply w-5 h-4.75 ml-2.5 text-black;
}

.ct-pame-table-download-csv__spinner {
  @apply tw-shared-icon-loading-spinner mx-auto;
}

.ct-pame-table-download-csv__button--disabled {
  @apply tw-shared-button--disabled;
}
</style>
