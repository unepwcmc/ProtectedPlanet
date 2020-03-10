<template>
  <button
    v-show="hasResults"
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
      resetting: false
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
      console.log('request more')
      if(this.resetting) { 
        this.resetting = false
        return false
      }
      
      this.$emit('request-more', this.currentPage + 1)
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
    },

    viewAll () {
      console.log('submit view all')

      this.scrollMagicHandlers()
    }
  }
} 
</script>