<template>
  <div class="ct-download">
    <button
      class="download__trigger"
      :class="{ 'ct-download__trigger--disabled': downloadDisabled }"
      :disabled="downloadDisabled"
      @click="toggleDownloadPane"
    >
      <span
        class="download__trigger-text"
        v-text="buttonText"
      />
    </button>
    <div
      class="download__target"
      :class="{ active: showPopup }"
    >
      <DownloadPopup
        :options
        @select="clickDownloadOption"
      />
    </div>
    <DownloadCommercial
      :isActive="showCommercialModal"
      :text="textCommercial"
      @close="closeCommercialModal"
      @nonCommercial="clickNonCommercial"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import DownloadCommercial from '@/components/Download/Commercial.vue'
import DownloadPopup from '@/components/Download/Popup.vue'
import useAnalytics from '@/composables/useAnalytics'
import { useDownloadStore, type DownloadItemParams } from '@/stores/useDownloadStore'
import type { DownloadOption, DownloadProps } from '@/types/backend'

const { trackEvent } = useAnalytics()

type Download = DownloadProps
const props = withDefaults(defineProps<Download>(), {
  downloadDisabled: false
})

const downloadStore = useDownloadStore()

const selectedDownloadOption = ref<DownloadOption | null>(null)
const showCommercialModal = ref(false)
const showPopup = ref(false)

function addNewDownloadItem() {
  const params = selectedDownloadOption.value?.params
  if (!params) return

  const item: DownloadItemParams = { ...params, id: Math.round(Math.random() * 100000) }
  downloadStore.addNewDownloadItem(item)
  selectedDownloadOption.value = null
}

function clickDownloadOption(option: DownloadOption) {
  showPopup.value = false
  selectedDownloadOption.value = option

  if (option.commercialAvailable) {
    showCommercialModal.value = true
  }
  else {
    addNewDownloadItem()
  }

  if (props.gaId) {
    trackEvent('download_request', { label: `${props.gaId} request - ${option.title}` })
  }
}

function clickNonCommercial() {
  const option = selectedDownloadOption.value
  if (option?.params?.domain === 'search') {
    selectedDownloadOption.value = {
      ...option,
      params: {
        ...option.params,
        filters: downloadStore.searchFilters,
        search: downloadStore.searchTerm
      }
    }
  }

  closeCommercialModal()
  addNewDownloadItem()
}

function closeCommercialModal() {
  showCommercialModal.value = false
}

function toggleDownloadPane() {
  if (props.downloadDisabled) return
  showPopup.value = !showPopup.value
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-download__trigger--disabled {
  @apply tw-shared-button--disabled;
}
</style>
