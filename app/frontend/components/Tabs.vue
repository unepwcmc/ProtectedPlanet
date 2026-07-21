<template>
  <div class="ct-tabs">
    <ul class="ct-tabs__triggers">
      <li
        v-for="tab in tabs"
        :key="tab.id"
        class="tab__trigger"
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
        class="ct-tab__target ct-tab__target--active"
        :datTabPanel="tab.id"
        role="tabpanel"
      >
        <div
          v-if="tab.bodyHtml"
          class="ct-tab__body"
          v-html="tab.bodyHtml"
        />
        <slot
          :name="`tab-${tab.id}`"
          :tab="tab"
          :selectedId="selectedId"
        />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import type { TabsProps } from '@/types/backend/tab'

// Match by id or by title (mirrors the legacy ?tab= param behaviour).
const props = defineProps<TabsProps>()
const emit = defineEmits<{ change: [id: number] }>()

function initialTabId() {
  const preset = props.tabs.find(
    t => String(t.id) === String(props.preselectedTab) || t.title === props.preselectedTab
  )
  return preset ? preset.id : props.tabs[0]?.id
}

const selectedId = ref(initialTabId())

function select(id: number) {
  selectedId.value = id
  emit('change', id)
}
</script>

<style scoped lang="css">
@reference "tailwindcss";

.ct-tabs__triggers {
  @apply m-0 flex list-none gap-8 overflow-x-auto p-0 md:flex-wrap;
}

.ct-tab__trigger {
  @apply tw-shared-base-container shrink-0 cursor-pointer border-b-2 border-transparent pb-1 text-[1.125rem] leading-[1.3] text-theme-grey-dark transition-colors hover:border-theme-primary md:text-[1.25rem];
}

.ct-tab__trigger--active {
  @apply border-theme-primary font-bold text-theme-grey-black;
}

.ct-tab__target {
  @apply pt-4;
}

.ct-tab__body {
  @apply text-base leading-[1.3] text-theme-grey-black;
}

/* v-html content has no classes to hook Tailwind onto directly, so it's styled here. */
.ct-tab__body :deep(p) {
  margin: 0;
}

.ct-tab__body :deep(a) {
  @apply text-theme-primary underline;
}

.ct-tab__body :deep(a):hover {
  @apply text-theme-primary-dark no-underline;
}
</style>
