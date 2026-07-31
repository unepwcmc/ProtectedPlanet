<template>
  <li class="ct-download-item">
    <span
      class="modal__li-title"
      v-text="title"
    />
    <p
      v-show="hasFailed"
      class="modal__li-failed"
    >
      <span
        class="modal__li-text"
        v-text="text.failed"
      />
    </p>
    <p
      v-show="isGenerating"
      class="modal__li-generating"
    >
      <span
        class="modal__li-text"
        v-text="text.generating"
      />
    </p>
    <a
      v-show="isReady"
      class="modal__li-download"
      :href="url"
      @click="trackDownloadClick"
    >
      <span
        class="modal__li-text"
        v-text="text.download"
      />
    </a>
    <span
      class="modal__li-delete"
      @click="deleteItem"
    />
  </li>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { getJson, postJson } from '@/lib/http'
import { useAnalytics } from '@/composables/useAnalytics'
import { useDownloadStore, type DownloadItemParams } from '@/stores/useDownloadStore'
import type { DownloadModalProps } from '@/types/backend'

const { trackEvent } = useAnalytics()

const props = defineProps<{
  endpointCreate: string
  endpointPoll: string
  gaId?: string
  params: DownloadItemParams
  text: DownloadModalProps['textStatus']
}>()

const downloadStore = useDownloadStore()

const hasFailed = ref(false)
const id = ref<number | string>('')
const title = ref('')
const url = ref('')
const updatedParams = ref<DownloadItemParams | ''>('')
let interval: ReturnType<typeof window.setInterval> | null = null

const isGenerating = computed(() => !hasFailed.value && url.value === '')
const isReady = computed(() => url.value !== '')

interface DownloadResponseData {
  hasFailed: boolean
  id?: number | string
  title: string
  url: string
  token?: string
}

function updateDownloadItem(data: DownloadResponseData) {
  hasFailed.value = data.hasFailed
  id.value = 'id' in data && data.id !== undefined ? data.id : Math.round(Math.random() * 100000)
  title.value = data.title
  url.value = data.url
  updatedParams.value = { ...props.params, backEndToken: data.token }
}

function startPolling() {
  interval = window.setInterval(ajaxRequestDownloadStatus, 15000)
}

function stopPolling() {
  if (interval !== null) window.clearInterval(interval)
}

function toQueryParams(params: DownloadItemParams): Record<string, string> {
  return Object.fromEntries(
    Object.entries(params)
      .filter(([, value]) => value !== undefined)
      .map(([key, value]) => [key, typeof value === 'string' ? value : JSON.stringify(value)])
  )
}

function ajaxRequestDownload() {
  postJson<DownloadResponseData>(props.endpointCreate, props.params)
    .then(updateDownloadItem)
    .catch((error) => {
      console.error(error)
      updateDownloadItem({
        hasFailed: true,
        title: `${props.params.token} .${props.params.format}`,
        url: ''
      })
    })

  startPolling()
}

function ajaxRequestDownloadStatus() {
  if (isReady.value || hasFailed.value) {
    stopPolling()
    return
  }

  getJson<DownloadResponseData>(props.endpointPoll, updatedParams.value ? toQueryParams(updatedParams.value) : undefined)
    .then(updateDownloadItem)
    .catch((error) => {
      console.error('error', error)
      stopPolling()
      hasFailed.value = true
    })
}

function deleteItem() {
  downloadStore.deleteDownloadItem(props.params)
  stopPolling()
}

function trackDownloadClick() {
  if (props.gaId) {
    trackEvent('download', { label: `${props.gaId} file - ${title.value}` })
  }
}

onMounted(ajaxRequestDownload)

onUnmounted(stopPolling)
</script>
