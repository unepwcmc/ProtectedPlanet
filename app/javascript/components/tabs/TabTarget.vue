<template>
  <div :class="['tab__target', { 'active': isActive }]" >
    <slot></slot>
  </div>
</template>

<script>
export default {
  name: 'tab-target',

  props: {
    id: {
      type: Number,
      required: true
    }
  },

  computed: {
    isActive () {
      return this.id == this.$attrs['selected-id'] //need to do this way for ie11
    }
  },

  watch: {
    isActive(isActive) {
      if (isActive) {
        this.resizeMapsInTab()
      }
    }
  },

  mounted() {
    if (this.isActive) {
      this.resizeMapsInTab()
    }
  },

  methods: {
    resizeMapsInTab() {
      // Mapbox initialises at 0×0 inside display:none tabs; resize once visible.
      this.$nextTick(() => {
        this.$eventHub.$emit('map:resize')
      })
    }
  }
}
</script>