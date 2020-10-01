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
  }
}
</script>