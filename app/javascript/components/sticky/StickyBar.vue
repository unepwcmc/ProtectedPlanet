<template>
  <div :class="` ${targetElementClass} sticky-bar`">
    <slot />
  </div>  
</template>

<script>
import ScrollMagic from 'scrollmagic'

export default {
  name: 'StickyBar',

  props: {
    triggerElement: {
      type: String,
      required: true
    }
  },

  data () {
    return {
      targetElementClass: 'sm-target-sticky' 
    }
  },

  mounted () {
    this.scrollMagicHandlers()
  },

  methods: {
    scrollMagicHandlers () {
      let scrollMagicSticky = new ScrollMagic.Controller()

      new ScrollMagic.Scene({ triggerElement: this.triggerElement, reverse: true })
        .triggerHook('onLeave')
        .setClassToggle(`.${this.targetElementClass}`, 'sticky-bar--stuck')
        .addTo(scrollMagicSticky)
    }
  }
}
</script>
