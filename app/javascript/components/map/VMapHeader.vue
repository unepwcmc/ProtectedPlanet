<template>
  <div class="v-map-header">
    <div class="v-map-header__title">
      {{ title }}
    </div>
    <div
      v-if="closeable"
      :class="['v-map-header__close', closeStateClass]"
      @click="toggle"
    />
  </div>
</template>
<script>
export default {
  model: {
    event: 'toggle',
    prop: 'filtersShown'
  },

  props: {
    title: {
      type: String,
      required: true
    },
    closeable: {
      type: Boolean,
      default: false
    },
    filtersShown: {
      type: Boolean,
      default: true
    }
  },

  computed: {
    closeStateClass () {
      return {
        'closed': !this.filtersShown
      } 
    }
  },

  methods: {
    toggle() {
      this.$emit('toggle')
    }
  }
}
</script>