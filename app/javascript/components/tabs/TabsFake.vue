<template>
  <ul class="tabs--fake">
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
    }
  },

  data () {
    return {
      selectedId: 0
    }
  },

  created () {
    this.setDefaultTab()
    this.$eventHub.$on('reset-search', this.reset)
  },

  methods: {
    click (selectedId) {
      this.selectedId = selectedId

      this.$emit('click:tab', selectedId)
    },

    setDefaultTab () {
      this.selectedId = this.children[0].id
    },

    reset () {
      this.setDefaultTab()
    }
  }
}
</script>