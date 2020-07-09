<template>
  <div class="v-map-header">
    <div class="v-map-header__title">
      {{ title }}
    </div>
    <div
      v-if="closeable"
      class="v-map-header__close"
      @click="onClose"
    />
  </div>
</template>
<script>
export default {
  model: {
    event: 'change',
    prop: 'title'
  },
  props: {
    title: {
      type: String,
      required: true
    },
    closeable: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    onClose() {
      this.$emit('close')
    }
  }
}
</script>