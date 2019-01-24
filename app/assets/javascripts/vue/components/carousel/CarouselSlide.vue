<template>
  <div class="v-carousel-slide">
    <slot></slot>
  </div>
</template>

<script>
module.exports = {
  name: 'carousel-slide',

  data () {
    return {
      slots: this.$slots.default
    }
  },

  mounted() {
    this.slots.forEach(child => {
      child.elm.classList.remove("init-hidden")
    })
  },
}
</script>