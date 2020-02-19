<template>
  <button
    v-html="text"
    class="button--all"
    @click="viewAll"
  />
</template>

<script>
import ScrollMagic from 'scrollmagic'

export default {
  name: 'pagination-more',

  props: {
    text: {
      type: String,
      required: true
    },
    smTriggerElement: {
      type: String,
      required: true
    }
  }, 

  data () {
    return {
      currentPage: 1
    }
  },

  methods: {
    requestMore () {
      console.log('request more')
      this.$emit('request-more', this.currentPage + 1)
    },

    scrollMagicHandlers () {
      let scrollMagicInfiniteScroll = new ScrollMagic.Controller()

      new ScrollMagic.Scene({ triggerElement: `.${this.smTriggerElement}` })
        .triggerHook('onEnter')
        .addTo(scrollMagicInfiniteScroll)
        .on('enter', () => {
          this.requestMore()
        })
    },

    viewAll () {
      console.log('submit view all')

      this.scrollMagicHandlers()
    }
  }
} 
</script>