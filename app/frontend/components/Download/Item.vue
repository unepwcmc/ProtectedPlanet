<template>
  <li class="ct-download-item">
    <span
      class="ct-download-item__title"
      v-text="title"
    />
    <p
      v-show="hasFailed"
      class="ct-download-item__status ct-download-item__status--failed"
    >
      <IconWarning class="ct-download-item__status-icon ct-download-item__status-icon--failed" />
      <span
        class="ct-download-item__status-text"
        v-text="text.failed"
      />
    </p>
    <p
      v-show="isGenerating"
      class="ct-download-item__status ct-download-item__status--generating"
    >
      <IconLoadingSpinner class="ct-download-item__status-icon ct-download-item__status-icon--generating" />
      <span
        class="ct-download-item__status-text"
        v-text="text.generating"
      />
    </p>
    <a
      v-show="isReady"
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

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-download-item {
  @apply
  bg-theme-grey-xlight
  tw-shared-base-flex-gap-3
  items-center
  justify-end
  tw-shared-font-hind-siliguri__normal-base-md-xl-grey-black
  min-h-10
  px-2.5
  md:h-15.5
  md:px-5.5;
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
  shrink-0
  gap-2.5
  size-8
  px-0
  md:w-auto
  md:px-6.75;
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
