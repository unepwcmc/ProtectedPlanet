<template>
  <span :class="smTriggerElement"></span>
</template>

<script>
import ScrollMagic from 'scrollmagic'

export default {
  name: 'pagination-infinity-scroll',

  props: {
    smTriggerElement: {
      type: String,
      required: true
    },
    total: {
      default: 0,
      type: Number
    },
    totalPages: {
      default: 0,
      type: Number
    }
  }, 

  data () {
    return {
      currentPage: 0,
      scrollMagicHandlersActive: false
    }
  },

  mounted () {
    this.scrollMagicHandlerInit()
    this.scrollMagicHandlerAdd()
    this.$eventHub.$on('reset:pagination', this.reset)
  },

  computed: {
    hasMoreResults () {
      return this.total > 0
    }
  },

  methods: {
    requestMore () {
      console.log('request more')
      this.currentPage = this.currentPage + 1
      
      this.$emit('request-more', this.currentPage)
      
      if(!this.scrollMagicHandlersActive) { 
        this.scrollMagicHandlerAdd()
      }

      if(this.currentPage == this.totalPages) { 
        this.scrollMagicHandlerRemove()
      }
    },

    reset () {
      this.scrollMagicHandlerRemove()
      this.currentPage = 0
    },

    scrollMagicHandlerAdd () {
      this.scrollMagicController.addScene(this.scrollMagicScene)
      this.scrollMagicHandlersActive = true
    },

    scrollMagicHandlerInit () {
      console.log('init')
      this.scrollMagicController = new ScrollMagic.Controller()

      this.scrollMagicScene = new ScrollMagic.Scene({ triggerElement: `.${this.smTriggerElement}` })
        .triggerHook('onEnter')
        .on('enter', () => {
          this.requestMore()
        })
    },

    scrollMagicHandlerRemove () {
      this.scrollMagicController.removeScene(this.scrollMagicScene)
      this.scrollMagicHandlersActive = false
    }
  }
} 
</script>