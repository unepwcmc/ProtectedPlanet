<template>
  <p :class="{ active : isActive }" @click="clickTab()">{{ name }}</p>
</template>

<script>
  export default {
    name: 'chart-line-tab',

    props: {
      name: { required: true },
      selected: String
    },

    methods: {
      clickTab () {
        this.$emit('tabClicked', this.name)
      }
    },

    computed: {
      isActive () {
        return this.name == this.selected
      }
    }
  }
</script>