<template>
  <div class="tabs">
    <div class="container">
      <ul class="tabs__triggers">
        <tab-trigger
          v-for="tab, index in tabTriggers"
          :key="`${tab.id}-${index}`"
          :id="tab.id"
          :selected-id="selectedId"
          :title="tab.title"
          v-on:click:tab="click"
        />
      </ul>
    </div>
    <slot :selected-id="selectedId" />
  </div>
</template>
<script>
import TabTrigger from './TabTrigger.vue'
export default {
  name: 'tabs',
  components: { TabTrigger },
  props: {
    tabTriggers: {
      type: Array, // [ { id: Number, title: String } ] 
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
      this.selectedId = this.tabTriggers[0].id
    },
  }
}
</script>