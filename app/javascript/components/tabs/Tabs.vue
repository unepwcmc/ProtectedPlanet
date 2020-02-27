<template>
  <div class="tabs">
    <tab-trigger
      v-for="tab in tabs.triggers"
      :id="tab.id"
      :selected-id="selectedId"
      :title="tab.title"
      v-on:click:tab="click"
    />

    <tab-target
      v-for="tab in tabs.targets"
      :id="tab.id"
      :selected-id="selectedId"
      :content="tab.content"
    />
  </div>
</template>
<script>
import TabTarget from './TabTarget.vue'
import TabTrigger from './TabTrigger.vue'

export default {
  name: 'tabs',

  components: { TabTarget, TabTrigger },

  props: {
    tabs: {
      type: Object, 
      required: true
    }
  },

  data () {
    return {
      selectedId: 0
    }
  },

  created () {
    this.setDefaultTab()
  },

  methods: {
    click (selectedId) {
      this.selectedId = selectedId
    },

    setDefaultTab () {
      this.selectedId = this.tabs.triggers[0].id
    },
  }
}
</script>