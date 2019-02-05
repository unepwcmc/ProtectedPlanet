<template>
  <li :class="['carousel-slide', 'transition', widthClass]">
    <slot :slideScope="slideScope"></slot>
  </li>
</template>

<script>
var INPUT_SELECTORS = 'select, input, textarea, button, a, [tabindex]:not([tabindex="-1"])'

module.exports = {
  name: 'carousel-slide',

  props: {
    slideWidth: {
      default: 'full-width',
      type: String
    }
  },

  data: function () {
    return {
      widthClass: 'carousel-slide--' + this.slideWidth,
      slideScope: {},
      isActive: false,
      inputElements: []
    }
  },

  mounted: function () {
    this.inputElements = this.$el.querySelectorAll(INPUT_SELECTORS)
    this.setTabIndices()
  },

  watch: {
    isActive: function () {
      this.setTabIndices() 
    }
  },

  methods: {
    setTabIndices: function () {
      var tabIndex = this.isActive ? 0 : -1

      Array.prototype.forEach.call(this.inputElements, function (el) {
        el.tabIndex = tabIndex
        if(tabIndex === -1) { el.blur() }
      })
    }
  }
}
</script>