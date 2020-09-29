<template>
  <ul>
    <tab-fake
      v-for="(child, index) in children" 
      :key="index"
      :gaId="googleAnalyticsId(child)"
      :id="child.id"
      :selectedId="selectedId"
      :title="child.title"
      v-on:click:tab="click"
    />
  </ul>
</template>

<script>
import TabFake from './TabFake.vue'

export default {
  name: 'tabs-fake',

  components: { TabFake },

  props: {
    children: {
      type: Array, // [{ id: String, title: String }]
      required: true
    },
    defaultSelectedId: {
      default: '',
      type: String
    },
    gaId: {
      type: String
    },
    preSelectedId: {
      default: '',
      type: String
    }
  },

  data () {
    return {
      defaultId: this.children[0].id,
      selectedId: ''
    }
  },

  created () {
    this.$eventHub.$on('reset:tabs', this.reset)

    this.setInitialTab()
  },

  watch: {
    preSelectedId () {
      this.click(this.preSelectedId)
    }
  },

  methods: {
    click (selectedId) {
      this.selectedId = selectedId

      this.$emit('click:tab', selectedId)

      if(this.gaId) {
        const eventLabel = `${this.gaId} - ${selectedId}`
        this.$ga.event('Fake Tab', 'click', eventLabel)
      }
    },

    googleAnalyticsId (child) {
      return `${this.gaId} - ${this.child.title}`
    },

    reset () {
      this.selectedId = this.defaultId
    },

    setInitialTab () {
      if(this.defaultSelectedId) {
        this.defaultId = this.defaultSelectedId
      }

      let tabId = this.defaultId

      if(this.preSelectedId !== '') {
        this.children.filter(child => {
          if(child.id == this.preSelectedId) { 
            tabId = this.preSelectedId
          }
        })
      }

      this.selectedId = tabId
    }
  }
}
</script>