<template>
  <div
    class="v-map-toggler"
    tabindex="0"
    :class="{ 'v-map-toggler--active': active }"
    @keyup.enter.stop.prevent="toggle"
    @click.stop="toggle"
  >
    <div class="v-map-toggler__switch">
      {{ actionText }}
    </div>
  </div>
</template>
<script>
export default {
  model: {
    event: 'change',
    prop: 'active'
  },
  props: {
    active: {
      type: Boolean,
      required: true
    },
    onText: {
      type: String,
      default: 'ON',
    },
    offText: {
      type: String,
      default: 'OFF'
    }
  },
  computed: {
    actionText () {
      if (this.active) {
        return this.onText
      }

      return this.offText
    }
  },
  methods: {
    toggle (newState) {
      if (typeof newState === 'boolean') {
        this.$emit('change', newState)
      } else {
        this.$emit('change', !this.active)
      }
    }
  }
}
</script>