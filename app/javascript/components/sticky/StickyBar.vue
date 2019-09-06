<template>
  <div class="sticky-bar">
    <slot />
  </div>  
</template>

<script>
import ScrollMagic from 'scrollmagic'

export default {
  name: 'StickyBar',

  mounted () {
    this.scrollMagicHandlers()
  },

  methods: {
    scrollMagicHandlers () {
      let scrollMagicSticky = new ScrollMagic.Controller()

      new ScrollMagic.Scene({ triggerElement: '.sm-trigger-sticky', reverse: true })
        .triggerHook('onLeave')
        .setClassToggle('.sm-target-sticky', 'sticky-bar--stuck')
        .addTo(scrollMagicSticky)
    }
  }
}
</script>
