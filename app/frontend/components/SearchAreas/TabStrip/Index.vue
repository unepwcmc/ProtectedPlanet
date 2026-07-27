<template>
  <ul>
    <SearchAreasTabStripTab
      v-for="child in children"
      :id="child.id"
      :key="child.id"
      :gaId="googleAnalyticsId(child)"
      :selectedId
      :title="child.title"
      @click:tab="click"
    />
  </ul>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { trackEvent } from '@/lib/analytics'
import SearchAreasTabStripTab from '@/components/SearchAreas/TabStrip/Tab.vue'

interface TabStripChild {
  id: string
  title: string
}

const props = withDefaults(defineProps<{
  children: TabStripChild[]
  defaultSelectedId?: string
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

watch(() => props.preSelectedId, () => {
  click(props.preSelectedId)
})
</script>
