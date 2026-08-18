<template>
  <div
    class="ct-download-modal"
    :class="{ 'ct-download-modal--active': downloadStore.isModalActive }"
  >
    <div class="ct-download-modal__topbar">
      <span
        class="ct-download-modal__topbar-title"
        v-text="textDownload.title"
      />
      <button
        class="ct-download-modal__minimise"
        @click="toggleMinimise"
      >
        <IconMinus class="ct-download-modal__minimise-icon" />
      </button>
    </div>
    <div
      class="ct-download-modal__content"
      :class="{ 'ct-download-modal__content--minimised': downloadStore.isModalMinimised }"
    >
      <span
        class="ct-download-modal__title"
        v-text="textDownload.citationTitle"
      />
      <p
        class="ct-download-modal__citation"
        v-html="textDownload.citationText"
      />

      <ul class="ct-download-modal__list">
        <DownloadItem
          v-for="download in downloadStore.downloadItems"
          :key="download.id"
          :endpointCreate
          :endpointPoll
          :gaId
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
import IconMinus from '@/components/Icon/Minus.vue'
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-download-modal {
  @apply
  hidden
  fixed
  right-0
  bottom-0
  z-1
  w-full
  tw-shared-shadow-grey
  border
  border-b-0
  border-theme-grey-black
  bg-white
  md:w-150
  lg:w-187
  tw-shared-base-flex-col;
}

.ct-download-modal--active {
  @apply block;
}

.ct-download-modal__topbar {
  @apply
  flex
  items-center
  justify-between
  bg-theme-grey-black
  h-15.5
  md:h-21.75
  px-4.5
  md:px-6.5;
}

.ct-download-modal__topbar-title {
  @apply tw-shared-font-hind-siliguri__normal-base-md-xl-white;
}

.ct-download-modal__minimise {
  @apply tw-shared-button-basic;
}

.ct-download-modal__minimise-icon {
  @apply
  size-5
  text-white;
}

.ct-download-modal__content {
  @apply
  p-4.5
  md:p-6
  tw-shared-base-flex-col-gap-3;
}

.ct-download-modal__content--minimised {
  @apply hidden;
}

.ct-download-modal__title {
  @apply tw-shared-font-hind-siliguri__normal-xl-grey-black;
}

.ct-download-modal__citation {
  @apply tw-shared-font-hind-siliguri__light-base-grey-black;
}

.ct-download-modal__list {
  @apply tw-shared-base-flex-col-gap-3;
}
</style>
