<template>
  <li :class="['carousel-slide', widthClass]">
    <slot></slot>
  </li>
</template>

<script>
module.exports = {
  name: 'carousel-slide',

  props: {
    slideWidth: {
      default: 'full-width',
      type: String
    }
  },

  data () {
    return {
      slots: this.$slots.default,
      widthClass: `carousel-slide--${this.slideWidth}`
    }
  },

  mounted() {
    this.slots.forEach(child => {
      child.elm.classList.remove("init-hidden")
    })
  },
}
</script>