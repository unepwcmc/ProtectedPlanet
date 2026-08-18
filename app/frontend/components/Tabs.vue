<template>
  <div class="ct-tabs">
    <Teleport
      to="#vw-hero-tabs-target"
      :disabled="!hasHeroTabsTarget"
    >
      <ul class="ct-tabs__triggers">
        <li
          v-for="tab in tabs"
          :key="tab.id"
          class="ct-tabs__trigger"
          :class="{ 'ct-tabs__trigger--active': tab.id === selectedId }"
          role="tab"
          :ariaSelected="tab.id === selectedId"
          @click="select(tab.id)"
          v-html="tab.title"
        />
      </ul>
    </Teleport>
    <template
      v-for="tab in tabs"
      :key="`panel-${tab.id}`"
    >
      <div
        v-if="tab.id === selectedId"
        class="ct-tabs__target"
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
import { ref, onMounted } from 'vue'
import useAnalytics from '@/composables/useAnalytics'
import type { TabsProps } from '@/types/backend'

const { trackEvent } = useAnalytics()

type Tabs = TabsProps
// Match by id or by title (mirrors the legacy ?tab= param behaviour).
const props = defineProps<Tabs>()
const emit = defineEmits<{ change: [id: number] }>()

// Hero partials render an empty #vw-hero-tabs-target for the trigger row to teleport
// into, so it visually sits at the bottom of the hero while panel content (this
// component's actual mount point) stays where it was rendered. Falls back to
// rendering triggers in place when no hero target exists (e.g. component tests).
const hasHeroTabsTarget = ref(false)
onMounted(() => {
  hasHeroTabsTarget.value = document.querySelector('#vw-hero-tabs-target') !== null
})

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
  console.log('hihih')

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
@reference "#importtailwindcss";

.ct-tabs__triggers {
  @apply
  tw-shared-base-container
  tw-shared-base-flex-gap-8
  overflow-x-auto;
}

.ct-tabs__trigger {
  @apply
  shrink-0
  cursor-pointer
  border-b-2
  border-transparent
  pb-1
  tw-shared-font-hind-siliguri__light-lg-md-xl-grey-black
  transition-colors
  hover:border-theme-primary;
}

.ct-tabs__trigger--active {
  @apply
  border-theme-primary
  font-bold
  text-theme-grey-black;
}

</style>
