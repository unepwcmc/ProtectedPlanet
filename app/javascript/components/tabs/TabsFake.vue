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
      defaultId: this.children[0].id,
      selectedId: ''
    }
  },

  created () {
    this.$eventHub.$on('reset:tabs', this.reset)

    this.click(this.defaultId)
  },

  methods: {
    click (selectedId) {
      this.selectedId = selectedId

      this.$emit('click:tab', selectedId)
    },

    reset () {
      this.selectedId = this.defaultId
    }
  }
}
</script>