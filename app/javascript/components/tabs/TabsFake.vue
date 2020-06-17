<template>
  <ul>
    <tab-fake
      v-for="(child, index) in children" 
      :key="index"
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
    preSelected: {
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
    this.setInitialTab()
    this.$eventHub.$on('reset:tabs', this.reset)
  },

  methods: {
    click (selectedId) {
      this.selectedId = selectedId

      this.$emit('click:tab', selectedId)
    },

    reset () {
      this.selectedId = this.defaultId
    },

    setInitialTab () {
      if(this.defaultSelectedId) {
        this.defaultId = this.defaultSelectedId
      }

      let tabId = this.defaultId

      if(this.preSelected !== '') {
        if(this.children.filter(child.id == this.preSelected)) { 
          tabId = this.preSelected.id 
        }
      }
      
      this.click(tabId)
    }
  }
}
</script>