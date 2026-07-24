<template>
  <div class="ct-tabs">
    <ul class="ct-tabs__triggers">
      <li
        v-for="tab in tabs"
        :key="tab.id"
        class="ct-tabs__trigger"
        :class="{ active: tab.id === selectedId }"
        role="tab"
        :ariaSelected="tab.id === selectedId"
        @click="select(tab.id)"
        v-html="tab.title"
      />
    </ul>
    <template
      v-for="tab in tabs"
      :key="`panel-${tab.id}`"
    >
      <div
        v-if="tab.id === selectedId"
        class="ct-tabs__target ct-tabs__target--active"
        :data-tab-panel="tab.id"
        role="tabpanel"
      >
        <div
          v-if="tab.bodyHtml"
          class="ct-tabs__body"
          v-html="tab.bodyHtml"
        />
        <slot
          :name="`tab-${tab.id}`"
          :tab
          :selectedId
        />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { trackEvent } from '@/lib/analytics'
import type { TabsProps } from '@/types/backend'

type Tabs = TabsProps
// Match by id or by title (mirrors the legacy ?tab= param behaviour).
const props = defineProps<Tabs>()
const emit = defineEmits<{ change: [id: number] }>()

function initialTabId() {
  const preset = props.tabs.find(
    t => String(t.id) === String(props.preselectedTab) || t.title === props.preselectedTab
  )
  return preset ? preset.id : props.tabs[0]?.id
}

const selectedId = ref(initialTabId())

// Strips non-ASCII chars/newlines from CMS titles before putting them in the
// URL, matching the legacy Vue2 Tabs component's `removeEncodedChars`.
function sanitizeTabParam(title: string) {
  return title.replace(/[^\x00-\x7F]|\n/g, '')
}

function updateTabParam(id: number) {
  const tab = props.tabs.find(t => t.id === id)
  if (!tab) return
  const url = new URL(window.location.href)
  url.searchParams.set('tab', sanitizeTabParam(tab.title))
  window.history.replaceState({ page: 1 }, '', url)
}

function select(id: number) {
  const tab = props.tabs.find(t => t.id === id)
  if (props.gaId && tab) {
    trackEvent('click', { event_label: `${props.gaId} - Tab: ${tab.title}` })
  }
  selectedId.value = id
  updateTabParam(id)
  emit('change', id)
}

if (selectedId.value !== undefined) updateTabParam(selectedId.value)
</script>

<style scoped lang="css">
@reference "tailwindcss";

.ct-tabs__triggers {
  @apply m-0 flex list-none gap-8 overflow-x-auto p-0 md:flex-wrap;
}

.ct-tabs__trigger {
  @apply tw-shared-base-container shrink-0 cursor-pointer border-b-2 border-transparent pb-1 text-[1.125rem] leading-[1.3] text-theme-grey-dark transition-colors hover:border-theme-primary md:text-[1.25rem];
}

.ct-tabs__trigger--active {
  @apply border-theme-primary font-bold text-theme-grey-black;
}

.ct-tabs__target {
  @apply pt-4;
}

.ct-tabs__body {
  @apply text-base leading-[1.3] text-theme-grey-black;
}

/* v-html content has no classes to hook Tailwind onto directly, so it's styled here. */
.ct-tabs__body :deep(p) {
  margin: 0;
}

.ct-tabs__body :deep(a) {
  @apply text-theme-primary underline;
}

.ct-tabs__body :deep(a):hover {
  @apply text-theme-primary-dark no-underline;
}
</style>
