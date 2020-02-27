<template>
  <div
    :class="['tab__target', { 'active': isActive }]"
    v-html="content"
  />
</template>

<script>
export default {
  name: 'tab-target',

  props: {
    id: {
      type: Number,
      required: true
    },
    selectedId: {
      type: Number,
      required: true
    },
    content: {
      type: String,
      required: true
    }
  },

  computed: {
    isActive () {
      return this.id == this.selectedId
    }
  }
}
</script>