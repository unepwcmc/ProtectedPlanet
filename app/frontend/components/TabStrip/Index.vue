<template>
  <ul
    class="ct-tab-strip"
    role="tablist"
  >
    <TabStripTab
      v-for="child in children"
      :id="child.id"
      :key="child.id"
      :disabled
      :gaId="googleAnalyticsId(child)"
      :selectedId
      size="default"
      :title="child.title"
      @click:tab="click"
    />
  </ul>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import useAnalytics from '@/composables/useAnalytics'
import TabStripTab from '@/components/TabStrip/Tab.vue'

const { trackEvent } = useAnalytics()

interface TabStripChild {
  id: string
  title: string
}

const props = withDefaults(defineProps<{
  children: TabStripChild[]
  defaultSelectedId?: string
  disabled?: boolean
  gaId?: string
  preSelectedId?: string
}>(), {
  defaultSelectedId: '',
  gaId: '',
  preSelectedId: ''
})

const emit = defineEmits<{ 'click:tab': [id: string] }>()

const selectedId = ref(initialSelectedId())

function initialSelectedId() {
  if (props.preSelectedId && props.children.some(child => child.id === props.preSelectedId)) {
    return props.preSelectedId
  }

  return props.defaultSelectedId || props.children[0].id
}

function click(selectedTabId: string) {
  // Re-selecting the current tab changes nothing, and parents mirror our emit
  // back into preSelectedId — either way there is no work for them to redo.
  if (selectedTabId === selectedId.value) return

  selectedId.value = selectedTabId
  emit('click:tab', selectedTabId)

  if (props.gaId) {
    const selectedTab = props.children.find(child => child.id === selectedTabId)
    trackEvent('click', { event_label: `${props.gaId} - Tab: ${selectedTab?.title}` })
  }
}

function googleAnalyticsId(child: TabStripChild) {
  return `${props.gaId} - ${child.title}`
}

watch(() => props.preSelectedId, (value) => {
  if (value) click(value)
})
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-tab-strip {
  @apply
  tw-shared-base-flex-gap-3
  overflow-x-auto;
}

</style>
