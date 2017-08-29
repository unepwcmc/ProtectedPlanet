<template>
  <p :class="{ active : isActive }" @click="clickTab()">{{ name }}</p>
</template>

<script>
  module.exports = {
    name: 'tab-title',

    props: {
      name: { required: true },
      selected: String
    },

    methods: {
      clickTab: function () {
        this.$emit('tabClicked', this.name)
      }
    },

    computed: {
      isActive: function () {
        return this.name == this.selected
      }
    }
  }
</script>