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
    gaId: {
      type: String
    },
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

      if(this.gaId) {
        const selectedTab = this.tabTriggers.filter( trigger => {
          return trigger.id == selectedId
        })

        const eventLabel = `${this.gaId} - Tab: ${selectedTab[0].title}`
        this.$ga.event('Tab', 'click', eventLabel)
      }
    },

    setDefaultTab () {
      this.selectedId = this.tabTriggers[0].id
    },
  }
}
</script>