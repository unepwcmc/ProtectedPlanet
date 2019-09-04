<template>
  <li :class="['carousel-slide', 'transition', widthClass]">
    <slot :slideScope="slideScope"></slot>
  </li>
</template>

<script>
  const INPUT_SELECTORS = 'select, input, textarea, button, a, [tabindex]:not([tabindex="-1"])'

  export default {
    name: 'carousel-slide',

    props: {
      slideWidth: {
        default: 'full-width',
        type: String
      }
    },

    data () {
      return {
        widthClass: 'carousel-slide--' + this.slideWidth,
        slideScope: {},
        isActive: false,
        inputElements: []
      }
    },

    mounted () {
      this.inputElements = this.$el.querySelectorAll(INPUT_SELECTORS)
      this.setTabIndices()
    },

    watch: {
      isActive () {
        this.setTabIndices() 
      }
    },

    methods: {
      setTabIndices () {
        var tabIndex = this.isActive ? 0 : -1

        this.inputElements.forEach(el => {
          el.tabIndex = tabIndex
          if(tabIndex === -1) { el.blur() }
        })
      }
    }
  }
</script>