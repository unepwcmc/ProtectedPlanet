<template>
  <div
    class="modal--download"
    :class="{ active: downloadStore.isModalActive }"
  >
    <div class="modal__topbar">
      <span v-text="textDownload.title" />
      <span
        class="modal__minimise"
        @click="toggleMinimise"
      />
    </div>
    <div
      class="modal__content"
      :class="{ minimised: downloadStore.isModalMinimised }"
    >
      <span
        class="modal__title"
        v-text="textDownload.citationTitle"
      />
      <p v-html="textDownload.citationText" />

      <ul class="modal__ul">
        <DownloadItem
          v-for="download in downloadStore.downloadItems"
          :key="download.id"
          class="modal__li"
          :endpointCreate="endpointCreate"
          :endpointPoll="endpointPoll"
          :gaId="gaId"
          :params="download"
          :text="textStatus"
        />
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { watch } from 'vue'
import DownloadItem from '@/components/Download/Item.vue'
import { useDownloadStore } from '@/stores/useDownloadStore'
import type { DownloadModalProps } from '@/types/backend'

type DownloadModal = DownloadModalProps
defineProps<DownloadModal>()

const downloadStore = useDownloadStore()

downloadStore.initialiseStore()
window.addEventListener('beforeunload', downloadStore.updateLocalStorage)

watch(() => downloadStore.downloadItems, (items) => {
  if (items.length === 0) {
    downloadStore.toggleDownloadModal(false)
    downloadStore.minimiseDownloadModal(false)
  }
})

function toggleMinimise() {
  downloadStore.minimiseDownloadModal(!downloadStore.isModalMinimised)
}
</script>
