<template>
  <div class="tabs">
    <div class="tabs__scrollable">
      <ul class="tabs__triggers">
        <tab-trigger
          v-for="tab in tabTriggers"
          :key="tab._uid"
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