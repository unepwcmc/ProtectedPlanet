<template>
  <li class="ct-download-item">
    <span
      class="ct-download-item__title"
      v-text="title"
    />
    <p
      v-if="hasFailed"
      class="ct-download-item__status
      ct-download-item__status--failed"
    >
      <IconWarning
        class="ct-download-item__status-icon
      ct-download-item__status-icon--failed"
      />
      <span
        class="ct-download-item__status-text"
        v-text="text.failed"
      />
    </p>
    <p
      v-else-if="isGenerating"
      class="ct-download-item__status
      ct-download-item__status--generating"
    >
      <IconLoadingSpinner
        class="ct-download-item__status-icon
      ct-download-item__status-icon--generating"
      />
      <span
        class="ct-download-item__status-text"
        v-text="text.generating"
      />
    </p>
    <a
      v-else-if="isReady"
      class="ct-download-item__link"
      :href="url"
      @click="trackDownloadClick"
    >
      <span
        class="ct-download-item__link-text"
        v-text="text.download"
      />
      <IconDownload class="ct-download-item__link-icon" />
    </a>
    <button
      class="ct-download-item__delete"
      @click="deleteItem"
    >
      <IconCircleClose class="ct-download-item__delete-icon" />
    </button>
  </li>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { getJson, postJson } from '@/lib/http'
import useAnalytics from '@/composables/useAnalytics'
import IconCircleClose from '@/components/Icon/CircleClose.vue'
import IconDownload from '@/components/Icon/Download.vue'
import IconLoadingSpinner from '@/components/Icon/LoadingSpinner.vue'
import IconWarning from '@/components/Icon/Warning.vue'
import {
  useDownloads,
  POLL_INTERVAL_MS,
  POLL_TIMEOUT_MS,
  type DownloadItemParams
} from '@/composables/useDownloads'
import type { DownloadModalProps } from '@/types/backend'

const { trackEvent } = useAnalytics()

const props = defineProps<{
  endpointCreate: string
  endpointPoll: string
  gaId?: string
  params: DownloadItemParams
  text: DownloadModalProps['textStatus']
}>()

const downloads = useDownloads()

// props.params identifies the item; the live copy comes back out of the store so
// this stays correct when another tab edits the list. It stands in if the item
// has already been deleted.
const item = computed(() => downloads.downloadItems.find(({ id }) => id === props.params.id) ?? props.params)

// Status is never persisted — the server owns it, and a remembered "ready" url
// can outlive the file. Every page load rediscovers it by polling.
const hasFailed = ref(false)
const serverTitle = ref('')
const url = ref('')

const isGenerating = computed(() => !hasFailed.value && url.value === '')
const isReady = computed(() => url.value !== '')
const title = computed(() => serverTitle.value || `${item.value.token}.${item.value.format}`)

let interval: ReturnType<typeof window.setInterval> | null = null

interface DownloadResponseData {
  hasFailed: boolean
  title: string
  url: string
  token?: string
}

// Only what each endpoint reads. Download::Router::request keys off
// filters/search, and Download::Poller keys 'search' off backEndToken.
function createPayload(download: DownloadItemParams) {
  return {
    domain: download.domain,
    format: download.format,
    token: download.token,
    filters: download.filters,
    search: download.search
  }
}

function pollPayload(download: DownloadItemParams): Record<string, string> {
  const payload: Record<string, string> = {
    domain: download.domain,
    format: download.format,
    token: download.token
  }
  if (download.backEndToken !== undefined) payload.backEndToken = download.backEndToken

  return payload
}

function applyResponse(data: DownloadResponseData) {
  hasFailed.value = data.hasFailed
  serverTitle.value = data.title
  url.value = data.url

  // The digest a 'search' download is polled by only ever comes back from the
  // create request, so it has to outlive this page load. Every other domain is
  // polled by the `token` it already has, and storing the response's copy of it
  // would just be noise.
  const isNewDigest = item.value.domain === 'search'
    && data.token !== undefined
    && data.token !== item.value.backEndToken

  if (isNewDigest) downloads.patchDownloadItem(item.value.id, { backEndToken: data.token })
}

function markFailed() {
  hasFailed.value = true
  stopPolling()
}

function stopPolling() {
  if (interval !== null) window.clearInterval(interval)
  interval = null
}

// Asking the server to generate the file. Only ever reached for the click that
// requested this download — see useDownloads#consumeCreateRequest.
function requestDownload() {
  postJson<DownloadResponseData>(props.endpointCreate, createPayload(item.value))
    .then(applyResponse)
    .catch((error) => {
      console.error(error)
      markFailed()
    })
}

function pollDownloadStatus() {
  // A 'search' download is keyed off a digest only the create response carries,
  // so there is nothing to ask about until the tab that requested it stored one.
  if (item.value.domain === 'search' && item.value.backEndToken === undefined) return

  getJson<DownloadResponseData>(props.endpointPoll, pollPayload(item.value))
    .then(applyResponse)
    .catch((error) => {
      console.error(error)
      markFailed()
    })
}

function tick() {
  if (isReady.value || hasFailed.value) {
    stopPolling()
    return
  }

  if (Date.now() - item.value.createdAt > POLL_TIMEOUT_MS) {
    markFailed()
    return
  }

  pollDownloadStatus()
}

function start() {
  if (downloads.consumeCreateRequest(item.value.id)) requestDownload()
  else tick()

  interval = window.setInterval(tick, POLL_INTERVAL_MS)
}

function deleteItem() {
  downloads.deleteDownloadItem(item.value)
  stopPolling()
}

function trackDownloadClick() {
  if (props.gaId) {
    trackEvent('download', { label: `${props.gaId} file - ${title.value}` })
  }
}

onMounted(start)

onUnmounted(stopPolling)
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-download-item {
  @apply
  bg-theme-grey-xlight
  tw-shared-base-flex-gap-3
  items-center
  justify-end
  tw-shared-font-hind-siliguri__light-base-md-xl-grey-black
  px-2.5
  md:px-5.5
  md:min-h-14;
}

.ct-download-item__title {
  @apply
  grow
  overflow-hidden
  text-ellipsis
  whitespace-nowrap;
}

.ct-download-item__status {
  @apply
  tw-shared-base-flex-gap-3
  items-center;
}

.ct-download-item__status-icon--failed {
  @apply
  w-5.5
  h-4.75
  text-theme-red;
}

.ct-download-item__status-icon--generating {
  @apply
  size-10
  text-theme-grey-dark;
}

.ct-download-item__status-text {
  @apply
  hidden
  md:inline;
}

.ct-download-item__link {
  @apply
  tw-shared-button--download
  shrink-0;
}

.ct-download-item__link-text {
  @apply
  hidden
  md:inline;
}

.ct-download-item__link-icon {
  @apply size-4.75;
}

.ct-download-item__delete {
  @apply tw-shared-button-basic;
}

.ct-download-item__delete-icon {
  @apply
  size-7.25
  text-theme-grey-xdark;
}
</style>
