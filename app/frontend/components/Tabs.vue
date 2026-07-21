<template>
  <div class="tabs">
    <div class="container">
      <ul class="tabs__triggers">
        <li
          v-for="tab in tabs"
          :key="tab.id"
          class="tab__trigger"
          :class="{ active: tab.id === selectedId }"
          role="tab"
          :aria-selected="tab.id === selectedId"
          @click="select(tab.id)"
          v-html="tab.title"
        />
      </ul>
    </div>

    <!--
      v-if (NOT v-show): only the ACTIVE panel is in the DOM. Inactive panels are
      not rendered until selected and are torn down when you switch away.

      Real tab panels hold COMPONENTS (maps, search, charts...), not just copy, so
      each tab exposes a per-tab named slot `#tab-<id>`. Because the slot outlet sits
      inside the v-if, an inactive tab's slot is never invoked — its components are
      not created until the tab is shown, and unmount when you leave it. That kills
      the "hidden map initialises at 0x0" class of bug (no display:none components).

      This works because (a) the panel is part of THIS island's own render tree, so
      Vue handles v-if natively, and (b) any nested `data-mount` a panel's CMS HTML
      brings in is picked up by the island MutationObserver the moment the panel
      appears (see lib/islands.ts). Either way, no `v-show` needed.
    -->
    <template
      v-for="tab in tabs"
      :key="`panel-${tab.id}`"
    >
      <div
        v-if="tab.id === selectedId"
        class="tab__target active"
        :data-tab-panel="tab.id"
        role="tabpanel"
      >
        <!-- Trusted CMS copy for the tab (optional). -->
        <div
          v-if="tab.bodyHtml"
          class="tab__body"
          v-html="tab.bodyHtml"
        />
        <!-- Interactive components for this tab, as build-time child components. -->
        <slot
          :name="`tab-${tab.id}`"
          :tab="tab"
          :selected-id="selectedId"
        />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
// Vue 3 island rewrite of the Webpacker Tabs (app/javascript/components/tabs).
// Differences from the legacy component, on purpose:
//  - panels use v-if, not a CSS `.active` class over always-present DOM;
//  - CMS copy comes in as `bodyHtml` props (Pattern B) instead of ERB inside slots;
//  - no $ga / $eventHub (Vue 3 has no global bus) — GA + map-resize will be wired
//    via composables/emits when a real tab page is migrated. This file is the
//    v-if proof; the legacy <tabs> stays registered in Webpacker for live pages.
import { ref } from 'vue'
import type { TabsProps } from '@/types/backend/tab'

// Match by id or by title (mirrors the legacy ?tab= param behaviour).
const { tabs, preselectedTab = null } = defineProps<TabsProps>()
const emit = defineEmits<{ change: [id: number] }>()

function initialTabId() {
  const preset = tabs.find(
    t => String(t.id) === String(preselectedTab) || t.title === preselectedTab
  )
  return preset ? preset.id : tabs[0]?.id
}

const selectedId = ref(initialTabId())

function select(id: number) {
  selectedId.value = id
  emit('change', id)
}
</script>

<style scoped lang="css">
@reference "tailwindcss";

.tabs__triggers {
  @apply m-0 flex list-none gap-8 overflow-x-auto p-0 md:flex-wrap;
}

.tab__trigger {
  @apply shrink-0 cursor-pointer border-b-2 border-transparent pb-1 text-[1.125rem] leading-[1.3] text-theme-grey-dark transition-colors hover:border-theme-primary md:text-[1.25rem];
}

.tab__trigger.active {
  @apply border-theme-primary font-bold text-theme-grey-black;
}

.tab__target {
  @apply pt-4;
}

.tab__body {
  @apply text-base leading-[1.3] text-theme-grey-black;
}

/* v-html content has no classes to hook Tailwind onto directly, so it's styled here. */
.tab__body :deep(p) {
  margin: 0;
}

.tab__body :deep(a) {
  @apply text-theme-primary underline;
}

.tab__body :deep(a):hover {
  @apply text-theme-primary-dark no-underline;
}
</style>
