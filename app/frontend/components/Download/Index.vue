<template>
  <div class="ct-download">
    <button
      class="ct-download__trigger"
      :class="{
        'ct-download__trigger--disabled': downloadDisabled
      }"
      :disabled="downloadDisabled"
      @click="toggleDownloadPane"
    >
      <span
        class="ct-download__trigger-text"
        v-text="buttonText"
      />
      <IconDownload class="ct-download__trigger-icon" />
    </button>
    <DownloadPopup
      v-if="isPopupVisible"
      :options
      @select="clickDownloadOption"
    />
    <DownloadCommercial
      v-if="isCommercialModalVisible"
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
import IconDownload from '@/components/Icon/Download.vue'
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
const isCommercialModalVisible = ref(false)
const isPopupVisible = ref(false)

function addNewDownloadItem() {
  const params = selectedDownloadOption.value?.params
  if (!params) return

  const item: DownloadItemParams = { ...params, id: Math.round(Math.random() * 100000) }
  downloadStore.addNewDownloadItem(item)
  selectedDownloadOption.value = null
}

function clickDownloadOption(option: DownloadOption) {
  isPopupVisible.value = false
  selectedDownloadOption.value = option

  if (option.commercialAvailable) {
    isCommercialModalVisible.value = true
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
  isCommercialModalVisible.value = false
}

function toggleDownloadPane() {
  if (props.downloadDisabled) return
  isPopupVisible.value = !isPopupVisible.value
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-download {
  @apply relative;
}

.ct-download__trigger {
  @apply
  shrink-0
  tw-shared-button--download;
}

.ct-download__trigger--disabled {
  @apply tw-shared-button--disabled;
}

.ct-download__trigger-text {
  @apply
  hidden
  md:inline;
}

.ct-download__trigger-icon {
  @apply
  shrink-0
  w-5
  h-4.75;
}
</style>
