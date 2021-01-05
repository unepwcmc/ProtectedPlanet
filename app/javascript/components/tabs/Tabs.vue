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
    },
    preselectedTab: {
      type: String
    }
  },
  data () {
    return {
      selectedId: undefined,
      tab: undefined
    }
  },
  created () {
    this.setDefaultTabIndex()
  },
  methods: {
    click (selectedId) {
      this.setTab(selectedId)

      if(this.gaId) {
        const selectedTab = this.tabTriggers.filter( trigger => {
          return trigger.id == selectedId
        })

        const eventLabel = `${this.gaId} - Tab: ${selectedTab[0].title}`
        this.$ga.event('Tab', 'click', eventLabel)
      }

      this.updateTabParams(this.removeEncodedChars(this.tab))
    },

    setDefaultTabIndex () {
      if (this.preselectedTab === "") {
        this.setTab(this.tabTriggers[0].id )
        this.updateTabParams(this.removeEncodedChars(this.tab))
      }
      else {
        const tabParam = this.tabTriggers.find((tab) => {
          return this.removeEncodedChars(tab) === this.preselectedTab
        })

        if (tabParam) {
          this.setTab(tabParam.id)
        }
        else {
          this.setTab()
        }

        this.updateTabParams(this.removeEncodedChars(this.tab))
      }
    },

    setTab (id = 1) {
      this.selectedId = id
      this.tab = this.tabTriggers[this.selectedId - 1]
    },

    removeEncodedChars(tab) {
      return tab.title.replace(/[^\x00-\x7F]|\n/g, "")
    },

    updateTabParams(tabName) {
      let tabParams = new URLSearchParams(window.location.search)

      tabParams.set('tab', tabName)

      const newUrl = `${window.location.pathname}?${tabParams.toString()}`

      window.history.replaceState({ page: 1 }, null, newUrl)
    }
  }
}
</script>