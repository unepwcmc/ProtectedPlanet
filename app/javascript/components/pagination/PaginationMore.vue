<template>
  <button
    v-show="hasResults"
    v-html="text"
    class="button--all"
    @click="requestMore"
  />
</template>

<script>
import ScrollMagic from 'scrollmagic'

export default {
  name: 'pagination-more',

  props: {
    smTriggerElement: {
      type: String,
      required: true
    },
    text: {
      type: String,
      required: true
    },
    total: {
      type: Number,
      required: true
    }
  }, 

  data () {
    return {
      currentPage: 1,
      resetting: false,
      scrollMagicHandlersActive: false
    }
  },

  created () {
    this.$eventHub.$on('reset-search', this.reset)
  },

  computed: {
    hasResults () {
      return this.total > 0
    }
  },

  methods: {
    requestMore () {
      if(this.resetting) { 
        this.resetting = false
        return false
      }

      if(!this.scrollMagicHandlersActive) { 
        this.scrollMagicHandlersActive = true
        this.scrollMagicHandlers()
        this.currentPage = 0
      }

      this.currentPage = this.currentPage + 1
      console.log(this.currentPage)
      this.$emit('request-more', this.currentPage)
    },

    reset () {
      this.resetting = true
      this.currentPage = 1 
    },

    scrollMagicHandlers () {
      let scrollMagicInfiniteScroll = new ScrollMagic.Controller()

      new ScrollMagic.Scene({ triggerElement: `.${this.smTriggerElement}` })
        .triggerHook('onEnter')
        .addTo(scrollMagicInfiniteScroll)
        .on('enter', () => {
          this.requestMore()
        })
    }
  }
} 
</script>