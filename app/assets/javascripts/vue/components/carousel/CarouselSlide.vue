<template>
  <li :class="['carousel-slide', widthClass]">
    <slot :slideScope="slideScope"></slot>
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
      children: this.$children,
      widthClass: `carousel-slide--${this.slideWidth}`,
      slideScope: {}
    }
  }
}
</script>