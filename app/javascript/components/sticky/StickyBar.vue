<template>
  <div class="sticky-bar" v-bind:style="{ height: stickyBarHeight }">
    <div 
      ref="stickyBarWrapper"
      :class="[targetElementClass, id, 'sticky-bar__wrapper']"
    >
      <div class="sticky-bar__content">
        <slot />
      </div>
    </div>
  </div>
</template>

<script>
import ScrollMagic from 'scrollmagic'
import mixinResponsive from '../../mixins/mixin-responsive.js'

export default {
  name: 'sticky-bar',

  mixins: [ mixinResponsive],

  props: {
    triggerElement: {
      type: String,
      required: true
    }
  },

  data () {
    return {
      id: `js-sticky-${this._uid}`,
      targetElementClass: 'sm-target-sticky',
      stickyHeight: 0
    }
  },

  computed: {
    stickyBarHeight () {
      return `${this.stickyHeight}px`
    }
  },

  mounted () {
    this.$eventHub.$on('windowResized', this.calculateStickyBarHeight)
    this.calculateStickyBarHeight()
    this.scrollMagicHandlers()
  },

  methods: {
    scrollMagicHandlers () {
      let scrollMagicSticky = new ScrollMagic.Controller()

      new ScrollMagic.Scene({ triggerElement: this.triggerElement, reverse: true })
        .triggerHook('onLeave')
        .setClassToggle(`.${this.targetElementClass}`, 'sticky-bar--stuck')
        .addTo(scrollMagicSticky)
    },

    calculateStickyBarHeight () {
      this.stickyHeight = this.$refs.stickyBarWrapper.clientHeight
    }
  }
}
</script>
